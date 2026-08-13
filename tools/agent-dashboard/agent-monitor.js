'use strict';

const fs = require('fs');
const { quickBranch } = require('./git-monitor');

const STATUS = {
  WORKING: 'WORKING',
  WAITING: 'WAITING',
  REVIEWING: 'REVIEWING',
  COMPLETED: 'COMPLETED',
  BLOCKED: 'BLOCKED',
  FAILED: 'FAILED',
  UNKNOWN: 'UNKNOWN',
};

/**
 * Maps `claude agents --json` raw fields to our Status enum.
 *
 * Real values OBSERVED live on this machine (2026-08-13, two separate
 * live-fire rounds, Claude Code 2.1.229):
 *   - `kind:"interactive"` + `status:"busy"`
 *   - `kind:"background"` + `state:"working"` (a running agent — NOTE: the
 *     field is `"working"`, not `"running"` as an earlier revision of this
 *     comment assumed without having observed it; that guess was wrong and
 *     meant real WORKING background agents were silently falling through to
 *     UNKNOWN until this fix)
 *   - `kind:"background"` + `state:"blocked"` (`waitingFor` present, e.g.
 *     "input needed" — a plan-mode agent that finished investigating and is
 *     waiting on a human decision)
 *   - `kind:"background"` + `state:"stopped"` (only visible with `--all`;
 *     the *result* of a real `claude stop <id>` call — a background session
 *     can in fact be stopped, contrary to an earlier assumption. Mapped to
 *     COMPLETED: it's a deliberate, clean end, not a failure, and the UI
 *     already treats COMPLETED as "session disappeared from the default
 *     listing → play the leaving animation", which is exactly what happens)
 *
 * `status:"idle"` (interactive) and `state:"done"`/`"failed"` (background)
 * are still inferred from the CLI's own field naming, not yet observed —
 * kept mapped best-effort. `"running"` is kept too as a defensive alias in
 * case a future CLI version uses it, since it costs nothing. Anything
 * genuinely unrecognized falls through to UNKNOWN rather than throwing.
 */
function mapStatus(session) {
  if (session.kind === 'interactive') {
    if (session.status === 'busy') return STATUS.WORKING;
    if (session.status === 'idle') return STATUS.WAITING;
    return STATUS.UNKNOWN;
  }
  if (session.kind === 'background') {
    if (session.state === 'working' || session.state === 'running') return STATUS.WORKING;
    if (session.state === 'blocked') return STATUS.BLOCKED;
    if (session.state === 'done' || session.state === 'stopped') return STATUS.COMPLETED;
    if (session.state === 'failed') return STATUS.FAILED;
    return STATUS.UNKNOWN;
  }
  return STATUS.UNKNOWN;
}

class AgentMonitor {
  constructor({ adapter, store, projectCwd, hookActivityPath, pollIntervalMs = 2500 }) {
    this.adapter = adapter;
    this.store = store;
    this.projectCwd = projectCwd;
    this.hookActivityPath = hookActivityPath;
    this.pollIntervalMs = pollIntervalMs;

    this.prevBySessionId = new Map();
    this.activityBySessionId = new Map();
    this.branchCache = new Map();
    this._hookReadOffset = 0;
    this._timer = null;
  }

  start() {
    this._ticking = false;
    this._tick();
    this._timer = setInterval(() => this._tick(), this.pollIntervalMs);
  }

  stop() {
    if (this._timer) clearInterval(this._timer);
  }

  async _tick() {
    // `claude agents --json` (x2) + per-cwd git branch lookups can take
    // longer than pollIntervalMs, especially the first time each cwd's
    // branch is cached. Without this guard, overlapping ticks would each
    // read the same not-yet-updated `prevBySessionId` and log a spurious
    // duplicate "Session detected" for a session that hasn't actually
    // changed — exactly the fake/repeated activity this dashboard must not
    // produce.
    if (this._ticking) return;
    this._ticking = true;
    try {
      await this._doTick();
    } finally {
      this._ticking = false;
    }
  }

  async _doTick() {
    const available = await this.adapter.checkAvailable();
    this.store.update('bridge', {
      ...this.store.state.bridge,
      claudeAvailable: available,
      claudeVersion: this.adapter.getVersion(),
      claudeError: available ? null : this.adapter.getLastError(),
    });

    if (!available) {
      this.store.update('agents', []);
      this.store.update('otherSessions', []);
      return;
    }

    const [allRes, scopedRes] = await Promise.all([
      this.adapter.discoverSessions({ all: false }),
      this.adapter.discoverSessions({ all: false, cwd: this.projectCwd }),
    ]);

    if (!allRes.ok) {
      this.store.addLog('claude', `claude agents --json failed: ${allRes.error}`, 'error');
      return;
    }

    this._readHookActivity();

    const scopedIds = new Set(scopedRes.ok ? scopedRes.sessions.map((s) => s.sessionId) : []);

    const normalized = [];
    for (const s of allRes.sessions) {
      const inProject = scopedIds.has(s.sessionId) || s.cwd === this.projectCwd;
      // eslint-disable-next-line no-await-in-loop
      const agent = await this._normalize(s, inProject);
      normalized.push(agent);
    }

    for (const [sid, prev] of this.prevBySessionId) {
      if (!normalized.find((a) => a.sessionId === sid)) {
        this._recordActivity(sid, `Session ended or no longer visible (last known status: ${prev.status})`);
      }
    }

    this.prevBySessionId = new Map(normalized.map((a) => [a.sessionId, a]));

    this.store.update('agents', normalized.filter((a) => a.inProject));
    this.store.update('otherSessions', normalized.filter((a) => !a.inProject));
  }

  async _normalize(session, inProject) {
    const sessionId = session.sessionId;
    const status = mapStatus(session);
    const prev = this.prevBySessionId.get(sessionId);

    if (!prev) {
      this._recordActivity(
        sessionId,
        `Session detected (${session.kind}${session.name ? `: "${session.name}"` : ''})`,
      );
    } else if (prev.status !== status) {
      this._recordActivity(sessionId, `Status changed: ${prev.status} → ${status}`);
    }

    let branch = this.branchCache.get(session.cwd);
    if (branch === undefined) {
      branch = await quickBranch(session.cwd);
      this.branchCache.set(session.cwd, branch);
    }

    const lastActivityAt = prev && prev.status === status ? prev.lastActivityAt : Date.now();

    return {
      id: session.id || sessionId,
      sessionId,
      name: session.name || null,
      role: null,
      status,
      rawKind: session.kind,
      rawState: session.state || session.status || null,
      currentTask: session.name || null,
      progress: null,
      startedAt: session.startedAt || null,
      lastActivityAt,
      pid: session.pid || null,
      cwd: session.cwd || null,
      branch: branch || null,
      inProject,
      recentActivity: (this.activityBySessionId.get(sessionId) || []).slice(-25),
    };
  }

  _recordActivity(sessionId, text, source = 'claude') {
    const entry = { ts: Date.now(), text, source };
    const list = this.activityBySessionId.get(sessionId) || [];
    list.push(entry);
    if (list.length > 100) list.shift();
    this.activityBySessionId.set(sessionId, list);
    this.store.addLog('agent', `[${sessionId.slice(0, 8)}] ${text}`);
  }

  _readHookActivity() {
    try {
      if (!fs.existsSync(this.hookActivityPath)) return;
      const stat = fs.statSync(this.hookActivityPath);
      if (stat.size < this._hookReadOffset) this._hookReadOffset = 0;
      if (stat.size === this._hookReadOffset) return;

      const length = stat.size - this._hookReadOffset;
      const fd = fs.openSync(this.hookActivityPath, 'r');
      const buffer = Buffer.alloc(length);
      fs.readSync(fd, buffer, 0, length, this._hookReadOffset);
      fs.closeSync(fd);
      this._hookReadOffset = stat.size;

      for (const line of buffer.toString('utf8').split('\n')) {
        if (!line.trim()) continue;
        try {
          const evt = JSON.parse(line);
          if (evt.sessionId) {
            this._recordActivity(evt.sessionId, evt.summary || evt.toolName || 'tool event', 'hook');
          }
        } catch (_) {
          // malformed line, skip
        }
      }
    } catch (err) {
      this.store.addLog('bridge', `hook activity read error: ${err.message}`, 'warn');
    }
  }

  isHookActive() {
    try {
      if (!fs.existsSync(this.hookActivityPath)) return false;
      const stat = fs.statSync(this.hookActivityPath);
      return Date.now() - stat.mtimeMs < 5 * 60 * 1000;
    } catch (_) {
      return false;
    }
  }
}

module.exports = { AgentMonitor, STATUS, mapStatus };
