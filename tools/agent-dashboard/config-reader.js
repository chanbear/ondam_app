'use strict';

const fs = require('fs');
const path = require('path');

/**
 * Reads config/agents.json — a user-editable *display* registry (department/
 * role labels + name-matching hints), never a source of real agent data.
 * Re-read on every call (like docs-reader.js) so edits apply without a
 * restart. Malformed/missing file -> empty roster, never throws, never
 * fabricates a fallback roster.
 */
function readAgentRoster(repoRoot) {
  const configPath = path.join(repoRoot, 'tools', 'agent-dashboard', 'config', 'agents.json');
  try {
    const raw = fs.readFileSync(configPath, 'utf8');
    const parsed = JSON.parse(raw);
    const roster = Array.isArray(parsed.roster) ? parsed.roster : [];
    return { ok: true, roster, sourcePath: path.relative(repoRoot, configPath) };
  } catch (err) {
    return { ok: false, roster: [], error: err.message };
  }
}

module.exports = { readAgentRoster };
