#!/usr/bin/env node
'use strict';

/**
 * OPTIONAL, opt-in Claude Code hook. NOT installed automatically by the
 * dashboard — see hooks/settings.snippet.json and README.md for how to wire
 * it into a PROJECT-level `.claude/settings.json` yourself.
 *
 * Claude Code hooks receive a JSON payload on stdin (documented mechanism —
 * fields include `session_id`, `hook_event_name`, `tool_name`, `tool_input`,
 * `cwd`). This script extracts only a coarse, generic summary — never the
 * full `tool_input` verbatim, since that could contain file contents or
 * command arguments with secrets in them — and appends one redacted JSON
 * line to data/hook-activity.jsonl for agent-monitor.js to tail.
 *
 * Must never block or break the real Claude Code session it's attached to:
 * every error path below exits 0 with no stdout output.
 */

const fs = require('fs');
const path = require('path');

const OUT_PATH = path.join(__dirname, '..', 'data', 'hook-activity.jsonl');

function redact(text) {
  if (typeof text !== 'string' || !text) return text;
  return text
    .replace(/eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g, '[REDACTED]')
    .replace(/sk-[A-Za-z0-9_-]{16,}/g, '[REDACTED]')
    .replace(/gh[pousr]_[A-Za-z0-9]{20,}/g, '[REDACTED]')
    .replace(/sbp_[A-Za-z0-9]{20,}/g, '[REDACTED]')
    .replace(/Bearer\s+[A-Za-z0-9._-]{10,}/gi, 'Bearer [REDACTED]');
}

function summarize(payload) {
  const toolName = payload.tool_name || payload.hook_event_name || 'event';
  const input = payload.tool_input;
  let hint = '';
  if (input && typeof input === 'object') {
    // Only ever surface a short, generic descriptor — a file path or
    // command name — never full file contents or full command text.
    if (typeof input.file_path === 'string') hint = path.basename(input.file_path);
    else if (typeof input.command === 'string') hint = input.command.split(/\s+/)[0];
    else if (typeof input.pattern === 'string') hint = 'search';
  }
  const summary = hint ? `${toolName}: ${hint}` : toolName;
  return redact(summary).slice(0, 200);
}

function main() {
  let raw = '';
  process.stdin.on('data', (chunk) => {
    raw += chunk;
  });
  process.stdin.on('end', () => {
    try {
      const payload = JSON.parse(raw || '{}');
      const line = JSON.stringify({
        ts: Date.now(),
        sessionId: payload.session_id || null,
        event: payload.hook_event_name || null,
        toolName: payload.tool_name || null,
        cwd: payload.cwd || null,
        summary: summarize(payload),
      });
      fs.mkdirSync(path.dirname(OUT_PATH), { recursive: true });
      fs.appendFileSync(OUT_PATH, `${line}\n`);
    } catch (_) {
      // Never let a malformed payload or write failure affect the real
      // Claude Code session this hook is attached to.
    }
    process.exit(0);
  });
  process.stdin.on('error', () => process.exit(0));
}

main();
