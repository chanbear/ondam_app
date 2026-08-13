'use strict';

/**
 * Plain-Node test for agent-monitor.js's mapStatus() (no framework — matches
 * this tool's zero-dependency policy). Run with: node agent-monitor.test.js
 *
 * Added 2026-08-13 (Agent Workforce v2) specifically to lock in a real
 * regression found via live spawning: `state:"working"` and `state:"stopped"`
 * (both actually observed from `claude agents --json`) were previously
 * falling through to UNKNOWN because the code only checked for `"running"`
 * (a value that, per the code's own prior comment, had never actually been
 * observed — it was a guess). Every case below is either a value this
 * project has live-observed from the real CLI, or an explicitly-documented
 * "not yet observed, best-effort" case — never invented.
 */
const assert = require('assert');
const { STATUS, mapStatus } = require('./agent-monitor');

const results = [];
function test(name, fn) {
  try {
    fn();
    results.push({ name, pass: true });
  } catch (err) {
    results.push({ name, pass: false, detail: err.message });
  }
}

// ---- interactive sessions ----
test('interactive + status:busy -> WORKING', () => {
  assert.strictEqual(mapStatus({ kind: 'interactive', status: 'busy' }), STATUS.WORKING);
});
test('interactive + status:idle -> WAITING', () => {
  assert.strictEqual(mapStatus({ kind: 'interactive', status: 'idle' }), STATUS.WAITING);
});
test('interactive + an unrecognized status -> UNKNOWN, never throws', () => {
  assert.strictEqual(mapStatus({ kind: 'interactive', status: 'something-new' }), STATUS.UNKNOWN);
});

// ---- background sessions: real observed values (regression-critical) ----
test('REGRESSION: background + state:"working" -> WORKING (live-observed 2026-08-13, previously fell through to UNKNOWN)', () => {
  assert.strictEqual(mapStatus({ kind: 'background', state: 'working' }), STATUS.WORKING);
});
test('REGRESSION: background + state:"stopped" -> COMPLETED (live-observed via a real `claude stop`, previously fell through to UNKNOWN)', () => {
  assert.strictEqual(mapStatus({ kind: 'background', state: 'stopped' }), STATUS.COMPLETED);
});
test('background + state:"blocked" -> BLOCKED (live-observed: plan-mode agent waiting on human input)', () => {
  assert.strictEqual(mapStatus({ kind: 'background', state: 'blocked', waitingFor: 'input needed' }), STATUS.BLOCKED);
});
test('background + state:"done" -> COMPLETED (live-observed: a plan-mode read-only task finishing naturally)', () => {
  assert.strictEqual(mapStatus({ kind: 'background', state: 'done' }), STATUS.COMPLETED);
});

// ---- background sessions: not yet observed, best-effort / defensive ----
test('background + state:"running" (defensive alias, never observed on this CLI version) -> WORKING', () => {
  assert.strictEqual(mapStatus({ kind: 'background', state: 'running' }), STATUS.WORKING);
});
test('background + state:"failed" -> FAILED', () => {
  assert.strictEqual(mapStatus({ kind: 'background', state: 'failed' }), STATUS.FAILED);
});
test('background + an unrecognized state -> UNKNOWN, never throws', () => {
  assert.strictEqual(mapStatus({ kind: 'background', state: 'something-new' }), STATUS.UNKNOWN);
});

// ---- neither kind ----
test('an unrecognized kind -> UNKNOWN, never throws', () => {
  assert.strictEqual(mapStatus({ kind: 'something-else' }), STATUS.UNKNOWN);
});

// ---- report ----
const failed = results.filter((r) => !r.pass);
console.log('\n=== agent-monitor.test.js RESULTS ===');
for (const r of results) {
  console.log(`${r.pass ? 'PASS' : 'FAIL'} — ${r.name}${r.pass ? '' : `\n     ${r.detail}`}`);
}
console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
process.exit(failed.length ? 1 : 0);
