'use strict';

const { EventEmitter } = require('events');

/**
 * Defensive text redaction applied to every string before it's stored or
 * broadcast to the browser. The Bridge process never reads `.env`, Claude
 * Code credential files, or Supabase keys itself — so this is a second line
 * of defense against secrets that might appear incidentally in free text
 * (git commit messages, test output, Claude Code session names), not the
 * only line of defense.
 */
const SECRET_PATTERNS = [
  { name: 'jwt', regex: /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g },
  { name: 'sk-key', regex: /sk-[A-Za-z0-9_-]{16,}/g },
  { name: 'github-token', regex: /gh[pousr]_[A-Za-z0-9]{20,}/g },
  { name: 'supabase-key', regex: /sbp_[A-Za-z0-9]{20,}/g },
  { name: 'bearer', regex: /Bearer\s+[A-Za-z0-9._-]{10,}/gi },
  {
    name: 'kv-secret',
    regex: /((?:API|SECRET|TOKEN|PASSWORD|PASSWD|PIN|PRIVATE)[A-Z0-9_]*\s*[:=]\s*)(\S{4,})/gi,
    replacer: (_m, prefix) => `${prefix}[REDACTED]`,
  },
  {
    name: 'kr-phone',
    regex: /01[0-9][-.\s]?\d{3,4}[-.\s]?\d{4}/g,
    replacer: (m) => `${m.slice(0, 3)}-****-${m.slice(-4)}`,
  },
];

function redact(text) {
  if (typeof text !== 'string' || !text) return text;
  let out = text;
  for (const p of SECRET_PATTERNS) {
    out = p.replacer ? out.replace(p.regex, p.replacer) : out.replace(p.regex, '[REDACTED]');
  }
  return out;
}

const MAX_LOGS = 500;

class StateStore extends EventEmitter {
  constructor() {
    super();
    this.setMaxListeners(0);
    this.state = {
      bridge: { startedAt: Date.now(), claudeAvailable: null, claudeVersion: null, claudeError: null },
      agents: [],
      otherSessions: [],
      git: null,
      tests: {},
      testRuns: [],
      project: null,
      architecture: null,
    };
    this.logs = [];
  }

  addLog(source, message, level = 'info') {
    const entry = { ts: Date.now(), source, level, message: redact(String(message)) };
    this.logs.push(entry);
    if (this.logs.length > MAX_LOGS) this.logs.shift();
    this.emit('log', entry);
    return entry;
  }

  update(key, value) {
    this.state[key] = value;
    this.emit('state', { key, value });
  }

  getSnapshot() {
    return { ...this.state, logs: this.logs.slice(-150) };
  }
}

module.exports = { StateStore, redact };
