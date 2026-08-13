'use strict';

const { spawn } = require('child_process');
const path = require('path');

const COMMANDS = {
  analyze: ['flutter', ['analyze']],
  test: ['flutter', ['test']],
  build: ['flutter', ['build', 'apk', '--debug']],
};

const MAX_RUNS = 10;
const MAX_TAIL_LINES = 300;

/**
 * Runs real `flutter analyze`/`flutter test`/`flutter build apk --debug` in
 * `apps/<target>` — ONLY when explicitly triggered via `start()` (an
 * `/api/tests/run` POST from the browser, itself only sent on a button
 * click). Never invoked automatically, never looped, never runs two
 * invocations of the same target+cmd concurrently.
 */
class TestRunner {
  constructor({ store, repoRoot }) {
    this.store = store;
    this.repoRoot = repoRoot;
    this.activeKeys = new Set();
    this.runs = [];
  }

  isBusy(target, cmd) {
    return this.activeKeys.has(`${target}:${cmd}`);
  }

  start(target, cmd) {
    if (!['senior', 'guardian'].includes(target)) {
      return { ok: false, error: `invalid target: ${target}` };
    }
    if (!COMMANDS[cmd]) {
      return { ok: false, error: `invalid cmd: ${cmd}` };
    }
    const key = `${target}:${cmd}`;
    if (this.activeKeys.has(key)) {
      return { ok: false, error: 'already running' };
    }

    const cwd = path.join(this.repoRoot, 'apps', target);
    const [bin, args] = COMMANDS[cmd];
    const runId = `${key}-${Date.now()}`;
    const run = {
      runId,
      target,
      cmd,
      status: 'RUNNING',
      startedAt: Date.now(),
      endedAt: null,
      exitCode: null,
      tail: [],
    };

    this.activeKeys.add(key);
    this.runs.unshift(run);
    if (this.runs.length > MAX_RUNS) this.runs.pop();
    this._publish();
    this.store.addLog('test', `Started: ${target} ${cmd} (${bin} ${args.join(' ')})`);

    let child;
    try {
      child = spawn(bin, args, { cwd, shell: true, windowsHide: true });
    } catch (err) {
      run.status = 'FAIL';
      run.endedAt = Date.now();
      this.activeKeys.delete(key);
      this.store.addLog('test', `Failed to start ${target} ${cmd}: ${err.message}`, 'error');
      this._publish();
      return { ok: false, error: err.message };
    }

    const onChunk = (streamName) => (chunk) => {
      const text = chunk.toString('utf8');
      run.tail.push({ stream: streamName, text });
      if (run.tail.length > MAX_TAIL_LINES) run.tail.shift();
      this.store.addLog('test', text.trimEnd(), streamName === 'stderr' ? 'warn' : 'info');
      this._publish();
    };
    child.stdout.on('data', onChunk('stdout'));
    child.stderr.on('data', onChunk('stderr'));

    child.on('close', (code) => {
      run.status = code === 0 ? 'PASS' : 'FAIL';
      run.exitCode = code;
      run.endedAt = Date.now();
      this.activeKeys.delete(key);
      this.store.addLog('test', `Finished: ${target} ${cmd} -> ${run.status} (exit ${code})`, code === 0 ? 'info' : 'error');
      this._recordResult(target, cmd, run);
      this._publish();
    });

    child.on('error', (err) => {
      run.status = 'FAIL';
      run.endedAt = Date.now();
      this.activeKeys.delete(key);
      this.store.addLog('test', `Process error for ${target} ${cmd}: ${err.message}`, 'error');
      this._publish();
    });

    return { ok: true, runId };
  }

  _recordResult(target, cmd, run) {
    const tests = { ...this.store.state.tests };
    tests[target] = { ...(tests[target] || {}) };
    tests[target][cmd] = { status: run.status, exitCode: run.exitCode, ranAt: run.endedAt };
    this.store.update('tests', tests);
  }

  _publish() {
    this.store.update(
      'testRuns',
      this.runs.map((r) => ({ ...r, tail: r.tail.slice(-80) })),
    );
  }
}

module.exports = { TestRunner };
