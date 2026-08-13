'use strict';

const { execFile } = require('child_process');

/**
 * Thin wrapper around the Claude Code CLI's officially documented scripting
 * interface. This file is the ONLY place that knows how to talk to `claude`
 * — everything else in the Bridge works with plain JS objects.
 *
 * Investigated 2026-08-13 against Claude Code 2.1.229 on Windows:
 *   - `claude agents --json` is explicitly documented in `claude agents --help`
 *     as: "Print active sessions (interactive and background) as a JSON
 *     array and exit (for scripting; does not require a TTY)". This is the
 *     only machine-readable, non-interactive way to list sessions that this
 *     CLI exposes — there is no separate "status" or "logs" subcommand per
 *     session, so getSessionStatus()/getActivities() below are implemented
 *     as lookups into the same discoverSessions() result, not separate CLI
 *     calls.
 *   - Deliberately NOT used: the undocumented `~/.claude/projects/*.jsonl`
 *     transcript files that Claude Code happens to write to disk. They
 *     exist and are readable, but their format is internal storage, not a
 *     supported interface — reading them would violate this project's
 *     "don't guess at internal files/private APIs" constraint.
 */
class ClaudeCodeAdapter {
  constructor({ timeoutMs = 8000 } = {}) {
    this.timeoutMs = timeoutMs;
    this._available = null;
    this._version = null;
    this._lastError = null;
  }

  /** Confirms the `claude` binary is on PATH and runnable. Cached after first success. */
  async checkAvailable() {
    if (this._available === true) return true;
    try {
      const out = await this._run(['--version']);
      this._version = out.trim();
      this._available = true;
      this._lastError = null;
    } catch (err) {
      this._available = false;
      this._lastError = err.message;
    }
    return this._available;
  }

  getVersion() {
    return this._version;
  }

  getLastError() {
    return this._lastError;
  }

  /**
   * @param {{all?: boolean, cwd?: string}} opts
   *   all: also include completed background sessions (`--all`)
   *   cwd: only sessions started under this directory (`--cwd`)
   * @returns {Promise<{ok: true, sessions: object[]} | {ok: false, error: string, sessions: []}>}
   */
  async discoverSessions({ all = false, cwd = null } = {}) {
    const args = ['agents', '--json'];
    if (all) args.push('--all');
    if (cwd) args.push('--cwd', cwd);

    try {
      const out = await this._run(args);
      const parsed = JSON.parse(out);
      if (!Array.isArray(parsed)) {
        throw new Error('unexpected output shape from `claude agents --json` (expected an array)');
      }
      return { ok: true, sessions: parsed };
    } catch (err) {
      return { ok: false, error: err.message, sessions: [] };
    }
  }

  /** Looks up one session's raw record from the full session list. No separate CLI call exists for this. */
  async getSessionStatus(sessionId) {
    const res = await this.discoverSessions({ all: true });
    if (!res.ok) return { ok: false, error: res.error };
    const session = res.sessions.find((s) => s.sessionId === sessionId);
    return session ? { ok: true, session } : { ok: false, error: 'session not found' };
  }

  /**
   * Claude Code's CLI does not expose a per-session activity/tool-use log to
   * external processes. This always returns an explicit "not exposed"
   * result rather than fabricating history — callers (agent-monitor.js)
   * build their own activity feed from observed state transitions instead,
   * or from the optional opt-in hook log if the user has enabled it.
   */
  async getActivities() {
    return { ok: false, error: 'not exposed by Claude Code CLI', activities: [] };
  }

  _run(args) {
    return new Promise((resolve, reject) => {
      execFile(
        'claude',
        args,
        { timeout: this.timeoutMs, windowsHide: true, shell: true, maxBuffer: 8 * 1024 * 1024 },
        (err, stdout, stderr) => {
          if (err) {
            reject(new Error((stderr && stderr.trim()) || err.message));
            return;
          }
          resolve(stdout);
        },
      );
    });
  }
}

module.exports = { ClaudeCodeAdapter };
