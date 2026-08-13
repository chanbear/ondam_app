'use strict';

/**
 * Plain-Node test for agent-spawner.js (no framework — matches this tool's
 * zero-dependency policy). Run with: node agent-spawner.test.js
 *
 * The real `child_process.spawn` is NEVER invoked here — every test injects
 * a fake `spawnFn` (and a fake, non-existent `claudeExecutable` path) via the
 * constructor. This is deliberate: the whole point of these tests is to
 * prove the ARGUMENT CONSTRUCTION is safe (cwd is never user-derived,
 * dangerous shell metacharacters in task text are rejected before spawnFn is
 * ever called, shell:false is always used) without ever launching a real,
 * billed Claude Code session. That live-fire proof is a separate, explicit,
 * user-confirmed step — this file must never be mistaken for it.
 *
 * REWRITTEN 2026-08-13 (second live-fire round) to match agent-spawner.js's
 * new behavior, discovered by live-testing the real CLI rather than assumed:
 *   - `claude` on this machine's PATH is a `.cmd`/`.ps1` shim; the real
 *     binary is a native `.exe` one directory level down
 *     (`node_modules/@anthropic-ai/claude-code/bin/claude.exe`). Spawning
 *     THAT directly with `shell:false` works — no shell needed at all, so
 *     `spawn()` now always uses `shell:false`.
 *   - `--session-id` is no longer sent: live testing showed `claude --bg`
 *     ignores it (prints `warning: --bg manages the session id; ignoring
 *     --session-id`) and assigns its own id. The real id is parsed from the
 *     CLI's own stdout confirmation line (`backgrounded · <id> · <name>`),
 *     so `spawn()` is now `async`/Promise-returning — every call site below
 *     awaits it.
 */
const assert = require('assert');
const { EventEmitter } = require('events');
const { AgentSpawner, VALID_DEPARTMENTS, MAX_TASK_LENGTH, resolveClaudeExecutable, matchDepartmentForAgent } = require('./agent-spawner');

const FAKE_CLAUDE_EXE = 'C:\\fake\\claude.exe';

class FakeStdin {
  constructor() { this.written = []; this.ended = false; }
  write(chunk) { this.written.push(chunk); return true; }
  end() { this.ended = true; }
}
class FakeChild extends EventEmitter {
  constructor() {
    super();
    this.stdin = new FakeStdin();
    this.stdout = new EventEmitter();
    this.stderr = new EventEmitter();
  }
  /** Simulates the CLI's real `--bg` confirmation line. */
  confirmBackgrounded(shortId, name) {
    this.stdout.emit('data', Buffer.from(`backgrounded \u00b7 ${shortId} \u00b7 ${name}\n`));
  }
}

function fakeStore(agents = []) {
  const logs = [];
  return {
    logs,
    state: { agents },
    addLog: (source, message, level) => logs.push({ source, message, level }),
  };
}

const results = [];
async function test(name, fn) {
  try {
    await fn();
    results.push({ name, pass: true });
  } catch (err) {
    results.push({ name, pass: false, detail: err.message });
  }
}

async function main() {
  // ---- validation: invalid department (including "open", which is a real
  // Office room but never a spawn target) ----
  await test('rejects an invalid department', async () => {
    const store = fakeStore();
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn: () => new FakeChild(), claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.spawn({ department: 'open', task: 'do something' });
    assert.strictEqual(r.ok, false);
    assert.ok(/invalid department/.test(r.error));
  });

  await test('rejects a department not in the whitelist at all', async () => {
    const store = fakeStore();
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn: () => new FakeChild(), claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.spawn({ department: 'ceo-office', task: 'do something' });
    assert.strictEqual(r.ok, false);
  });

  await test('accepts every real department in VALID_DEPARTMENTS', async () => {
    for (const dept of VALID_DEPARTMENTS) {
      const store = fakeStore();
      let capturedArgs = null;
      let child = null;
      const spawnFn = (cmd, args) => { capturedArgs = args; child = new FakeChild(); return child; };
      const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
      const promise = spawner.spawn({ department: dept, task: '조사만 하고 계획을 작성하라' });
      assert.ok(Array.isArray(capturedArgs), `department ${dept} should reach spawnFn`);
      child.confirmBackgrounded('abc12345', 'x');
      const r = await promise;
      assert.strictEqual(r.ok, true, `department ${dept} should be spawnable`);
    }
  });

  // ---- validation: empty / whitespace-only task ----
  await test('rejects an empty task', async () => {
    const store = fakeStore();
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn: () => new FakeChild(), claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.spawn({ department: 'backend', task: '   ' });
    assert.strictEqual(r.ok, false);
    assert.ok(/task is required/.test(r.error));
  });

  // ---- validation: task too long ----
  await test('rejects a task longer than MAX_TASK_LENGTH', async () => {
    const store = fakeStore();
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn: () => new FakeChild(), claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.spawn({ department: 'backend', task: 'x'.repeat(MAX_TASK_LENGTH + 1) });
    assert.strictEqual(r.ok, false);
    assert.ok(/too long/.test(r.error));
  });

  // ---- validation: control characters ----
  await test('rejects a task containing control characters', async () => {
    const store = fakeStore();
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn: () => new FakeChild(), claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.spawn({ department: 'backend', task: 'do it\x00now' });
    assert.strictEqual(r.ok, false);
  });

  // ---- normal spawn: correct cwd, shell:false, no --session-id, resolves
  // once the CLI's own confirmation line is parsed ----
  await test('a valid spawn calls spawnFn with the repo root as cwd, shell:false, no --session-id, and resolves with the CLI-confirmed id', async () => {
    const store = fakeStore();
    let capturedCmd = null;
    let capturedArgs = null;
    let capturedOpts = null;
    let child = null;
    const spawnFn = (cmd, args, opts) => { capturedCmd = cmd; capturedArgs = args; capturedOpts = opts; child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({
      store,
      repoRoot: 'C:\\Users\\kke05\\Downloads\\ondam_app-master\\ondam_app-master',
      spawnFn,
      claudeExecutable: FAKE_CLAUDE_EXE,
    });
    const promise = spawner.spawn({ department: 'backend', task: 'Phase 7 SMS 기능을 조사하고 계획을 작성하라' });

    assert.strictEqual(capturedCmd, FAKE_CLAUDE_EXE, 'must spawn the resolved real executable, not the bare "claude" shim name');
    assert.strictEqual(capturedOpts.cwd, 'C:\\Users\\kke05\\Downloads\\ondam_app-master\\ondam_app-master');
    assert.strictEqual(capturedOpts.shell, false, 'must never use shell:true — the real .exe needs no shell');
    assert.ok(!capturedArgs.includes('--session-id'), '--session-id is ignored (with a warning) by --bg on this CLI version and must not be sent');
    assert.ok(capturedArgs.includes('--bg'));
    assert.ok(!capturedArgs.includes('-p'), '-p/--print must never be combined with --bg');
    assert.ok(capturedArgs.includes('Phase 7 SMS 기능을 조사하고 계획을 작성하라'), 'task must be passed as the positional prompt argv element');
    assert.ok(capturedArgs.includes('--permission-mode'));
    assert.strictEqual(capturedArgs[capturedArgs.indexOf('--permission-mode') + 1], 'plan', 'spawned agents must default to plan mode, not autonomous execution');
    assert.ok(capturedArgs.includes('--max-budget-usd'), 'must always attempt to cap spend');

    child.confirmBackgrounded('a1b2c3d4', 'ondam-office-backend-x');
    const r = await promise;
    assert.strictEqual(r.ok, true);
    assert.strictEqual(r.sessionId, 'a1b2c3d4', 'sessionId returned to the caller must be the CLI-confirmed id, not a pre-generated guess');
  });

  // ---- the security-critical property: dangerous shell metacharacters are
  // rejected BEFORE task text ever becomes an argv element ----
  await test('SECURITY: task text containing shell metacharacters is rejected, spawnFn is never called', async () => {
    const maliciousTasks = [
      '"; rm -rf / #',
      '`whoami`',
      'task && del /f /q C:\\*',
      'task | type C:\\Windows\\System32\\config\\SAM',
      'a"^&|<>%b',
      'line1\nline2',
      'line1\rline2',
    ];
    for (const task of maliciousTasks) {
      const store = fakeStore();
      let spawnFnCalled = false;
      const spawnFn = () => { spawnFnCalled = true; return new FakeChild(); };
      const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
      const r = await spawner.spawn({ department: 'backend', task });
      assert.strictEqual(r.ok, false, `task with shell metacharacters must be rejected: ${JSON.stringify(task)}`);
      assert.strictEqual(spawnFnCalled, false, `a rejected task must never reach spawnFn: ${JSON.stringify(task)}`);
    }
  });

  await test('a task with ordinary punctuation (Korean text, parentheses, colons) is accepted and passed as a single argv element', async () => {
    const store = fakeStore();
    let capturedArgs = null;
    let child = null;
    const spawnFn = (cmd, args) => { capturedArgs = args; child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const task = 'Phase 7(message_check: Android SMS 조회, iOS 붙여넣기)의 구현 계획을 작성하라.';
    const promise = spawner.spawn({ department: 'backend', task });
    assert.strictEqual(capturedArgs.filter((a) => a === task).length, 1, 'task must appear as exactly one whole argv element, never split or concatenated');
    child.confirmBackgrounded('deadbeef', 'x');
    const r = await promise;
    assert.strictEqual(r.ok, true);
  });

  // ---- path traversal: cwd is always repoRoot, never derived from input ----
  await test('SECURITY: no request field can influence cwd (path traversal is structurally impossible)', async () => {
    const store = fakeStore();
    let capturedOpts = null;
    let child = null;
    const spawnFn = (cmd, args, opts) => { capturedOpts = opts; child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\safe\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    // Attempt to smuggle a path via any field the API accepts — spawn() only
    // destructures {department, task, name}, so extra fields are silently ignored.
    const promise = spawner.spawn({ department: 'backend', task: 'ok', cwd: '..\\..\\..\\Windows\\System32', projectPath: 'C:\\other' });
    assert.strictEqual(capturedOpts.cwd, 'C:\\safe\\repo');
    child.confirmBackgrounded('cafef00d', 'x');
    await promise;
  });

  // ---- spawn failure (synchronous throw from spawnFn, e.g. ENOENT-style) ----
  await test('a spawnFn that throws synchronously is reported as a clean failure, not a crash', async () => {
    const store = fakeStore();
    const spawnFn = () => { throw new Error('spawn claude ENOENT'); };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.spawn({ department: 'qa', task: 'run the test suite' });
    assert.strictEqual(r.ok, false);
    assert.ok(/ENOENT/.test(r.error));
  });

  // ---- executable resolution failure is a clean, honest failure — never a
  // silent fallback to shell:true ----
  await test('a failed executable resolution is reported as a clean failure, spawnFn is never called (never falls back to shell:true)', async () => {
    const store = fakeStore();
    let spawnFnCalled = false;
    const spawnFn = () => { spawnFnCalled = true; return new FakeChild(); };
    const spawner = new AgentSpawner({
      store,
      repoRoot: 'C:\\repo',
      spawnFn,
      claudeExecutable: null,
      resolveExecutable: () => null, // simulates "claude binary not found on this machine"
    });
    const r = await spawner.spawn({ department: 'qa', task: 'run the test suite' });
    assert.strictEqual(r.ok, false);
    assert.ok(/claude 실행 파일을 찾지 못했습니다/.test(r.error));
    assert.strictEqual(spawnFnCalled, false);
  });

  // ---- duplicate spawn prevention (two requests racing before either
  // resolves — the realistic "double click" scenario) ----
  await test('rejects a second spawn for the same department while the first is still in flight', async () => {
    const store = fakeStore();
    const children = [];
    const spawnFn = () => { const c = new FakeChild(); children.push(c); return c; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });

    const firstPromise = spawner.spawn({ department: 'qa', task: 'first task' });

    const second = await spawner.spawn({ department: 'qa', task: 'second task' });
    assert.strictEqual(second.ok, false);
    assert.ok(/이미 처리 중/.test(second.error));
    assert.strictEqual(children.length, 1, 'the rejected duplicate must never reach spawnFn');

    // A different department is unaffected by the same-department debounce.
    const otherPromise = spawner.spawn({ department: 'backend', task: 'unrelated task' });
    assert.strictEqual(children.length, 2);

    children[0].confirmBackgrounded('11111111', 'first');
    children[1].confirmBackgrounded('22222222', 'second');
    const [first, other] = await Promise.all([firstPromise, otherPromise]);
    assert.strictEqual(first.ok, true);
    assert.strictEqual(other.ok, true);
  });

  // ---- process bookkeeping cleanup (no leak in the pending map) ----
  await test('the pending-spawn bookkeeping entry is removed once the CLI confirms a session id', async () => {
    const store = fakeStore();
    let child = null;
    const spawnFn = () => { child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const promise = spawner.spawn({ department: 'docs', task: 'update docs' });
    assert.strictEqual(spawner.pending.size, 1);
    child.confirmBackgrounded('22222222', 'x');
    const r = await promise;
    assert.strictEqual(r.ok, true);
    assert.strictEqual(spawner.pending.size, 0);
  });

  await test('a close before any confirmation line is reported as a clean failure and logged (launch failed, not a real agent FAILED state)', async () => {
    const store = fakeStore();
    let child = null;
    const spawnFn = () => { child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const promise = spawner.spawn({ department: 'docs', task: 'update docs' });
    child.stderr.emit('data', Buffer.from('some launch error'));
    child.emit('close', 1);
    const r = await promise;
    assert.strictEqual(r.ok, false);
    assert.ok(store.logs.some((l) => l.source === 'spawn' && l.level === 'error'));
    assert.strictEqual(spawner.pending.size, 0);
  });

  // ---- department-busy rejection (Agent Workforce v2 §9): a REAL,
  // currently-live agent in state.agents blocks a same-department spawn,
  // independent of the short 5s duplicate-window debounce above ----
  const ROSTER = [
    { id: 'lead-01', department: 'management', match: { kind: 'interactive', nameContains: ['management', 'mgmt'] } },
    { id: 'senior-01', department: 'senior', match: { nameContains: ['senior'] } },
    { id: 'backend-01', department: 'backend', match: { nameContains: ['backend'] } },
  ];

  await test('rejects a spawn when a real WORKING agent already occupies that department', async () => {
    const store = fakeStore([
      { sessionId: 'abc', rawKind: 'background', name: 'ondam-office-senior-1', status: 'WORKING' },
    ]);
    const spawner = new AgentSpawner({
      store,
      repoRoot: 'C:\\repo',
      spawnFn: () => new FakeChild(),
      claudeExecutable: FAKE_CLAUDE_EXE,
      loadRoster: () => ROSTER,
    });
    const r = await spawner.spawn({ department: 'senior', task: 'do more senior work' });
    assert.strictEqual(r.ok, false);
    assert.ok(/이미 근무 중/.test(r.error));
  });

  await test('a real agent in a DIFFERENT department does not block this spawn', async () => {
    const store = fakeStore([
      { sessionId: 'abc', rawKind: 'background', name: 'ondam-office-senior-1', status: 'WORKING' },
    ]);
    let child = null;
    const spawnFn = () => { child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE, loadRoster: () => ROSTER });
    const promise = spawner.spawn({ department: 'backend', task: 'do backend work' });
    child.confirmBackgrounded('33333333', 'x');
    const r = await promise;
    assert.strictEqual(r.ok, true);
  });

  await test('a COMPLETED/FAILED agent in the same department does NOT block a new spawn (only occupied statuses count)', async () => {
    for (const status of ['COMPLETED', 'FAILED', 'UNKNOWN']) {
      const store = fakeStore([
        { sessionId: 'abc', rawKind: 'background', name: 'ondam-office-senior-1', status },
      ]);
      let child = null;
      const spawnFn = () => { child = new FakeChild(); return child; };
      const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE, loadRoster: () => ROSTER });
      const promise = spawner.spawn({ department: 'senior', task: 'do senior work' });
      child.confirmBackgrounded('44444444', 'x');
      const r = await promise;
      assert.strictEqual(r.ok, true, `status ${status} must not block a new spawn`);
    }
  });

  await test('matchDepartmentForAgent mirrors kind+nameContains OR matching, first roster entry wins', () => {
    const interactiveMgmt = matchDepartmentForAgent({ rawKind: 'interactive', name: 'anything' }, ROSTER);
    assert.strictEqual(interactiveMgmt.department, 'management');
    const byName = matchDepartmentForAgent({ rawKind: 'background', name: 'ondam-office-backend-99' }, ROSTER);
    assert.strictEqual(byName.department, 'backend');
    const noMatch = matchDepartmentForAgent({ rawKind: 'background', name: 'totally-unrelated' }, ROSTER);
    assert.strictEqual(noMatch, null);
  });

  // ---- Agent Stop (Agent Workforce v2 §3/§17): claude stop <shortId>,
  // never the full sessionId, and only ever for a session already present
  // in store.state.agents ----
  await test('stop() rejects a sessionId that is not a real, currently-registered agent', async () => {
    const store = fakeStore([]); // nothing registered
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.stop('not-a-real-session-id');
    assert.strictEqual(r.ok, false);
    assert.ok(/등록된 실제 Agent가 아닙니다/.test(r.error));
  });

  await test('stop() refuses to stop an interactive session (claude stop is background-only)', async () => {
    const store = fakeStore([
      { sessionId: 'interactive-1', id: 'interactive-1', rawKind: 'interactive', name: 'dev session' },
    ]);
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.stop('interactive-1');
    assert.strictEqual(r.ok, false);
    assert.ok(/background 세션 전용/.test(r.error));
  });

  await test('stop() calls the resolved executable with ["stop", shortId], shell:false, cwd:repoRoot — never the full UUID', async () => {
    const store = fakeStore([
      { sessionId: 'e102ddd7-94c7-4462-bb0e-e4242b275944', id: 'e102ddd7', rawKind: 'background', name: 'ondam-mgmt-validate' },
    ]);
    let capturedCmd = null;
    let capturedArgs = null;
    let capturedOpts = null;
    const execFileFn = (cmd, args, opts, cb) => { capturedCmd = cmd; capturedArgs = args; capturedOpts = opts; cb(null, 'stopped e102ddd7\n', ''); };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\safe\\repo', execFileFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.stop('e102ddd7-94c7-4462-bb0e-e4242b275944');
    assert.strictEqual(r.ok, true);
    assert.strictEqual(r.shortId, 'e102ddd7');
    assert.strictEqual(capturedCmd, FAKE_CLAUDE_EXE);
    assert.deepStrictEqual(capturedArgs, ['stop', 'e102ddd7']);
    assert.strictEqual(capturedOpts.shell, false);
    assert.strictEqual(capturedOpts.cwd, 'C:\\safe\\repo');
  });

  await test('stop() reports a real CLI failure (e.g. session already gone) as a clean error, not a crash', async () => {
    const store = fakeStore([
      { sessionId: 'ghost-full-id', id: 'deadbeef', rawKind: 'background', name: 'x' },
    ]);
    const execFileFn = (cmd, args, opts, cb) => cb(new Error('exit 1'), '', "No job matching 'deadbeef'.\n");
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', execFileFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.stop('ghost-full-id');
    assert.strictEqual(r.ok, false);
    assert.ok(/No job matching/.test(r.error));
  });

  await test('stop() never falls back to shell:true even if executable resolution fails', async () => {
    const store = fakeStore([
      { sessionId: 'sid', id: 'abcdef12', rawKind: 'background', name: 'x' },
    ]);
    let execFileFnCalled = false;
    const execFileFn = () => { execFileFnCalled = true; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', execFileFn, claudeExecutable: null, resolveExecutable: () => null });
    const r = await spawner.stop('sid');
    assert.strictEqual(r.ok, false);
    assert.strictEqual(execFileFnCalled, false);
  });

  // ---- permission-mode override (Agent Workforce v2, Phase 8 approval):
  // default stays 'plan'; an override is only honored when passed directly
  // (never from the public HTTP API, which never forwards it — see
  // server.js not reading parsed.permissionMode) ----
  await test('spawn() defaults to --permission-mode plan when no override is given', async () => {
    const store = fakeStore();
    let capturedArgs = null;
    let child = null;
    const spawnFn = (cmd, args) => { capturedArgs = args; child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const promise = spawner.spawn({ department: 'backend', task: 'investigate only' });
    assert.strictEqual(capturedArgs[capturedArgs.indexOf('--permission-mode') + 1], 'plan');
    child.confirmBackgrounded('55555555', 'x');
    await promise;
  });

  await test('spawn() honors an explicit, human-approved permissionMode override (e.g. acceptEdits)', async () => {
    const store = fakeStore();
    let capturedArgs = null;
    let child = null;
    const spawnFn = (cmd, args) => { capturedArgs = args; child = new FakeChild(); return child; };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const promise = spawner.spawn({ department: 'backend', task: 'implement it', permissionMode: 'acceptEdits' });
    assert.strictEqual(capturedArgs[capturedArgs.indexOf('--permission-mode') + 1], 'acceptEdits');
    child.confirmBackgrounded('66666666', 'x');
    const r = await promise;
    assert.strictEqual(r.ok, true);
  });

  await test('spawn() rejects an arbitrary/invalid permissionMode string, spawnFn is never called', async () => {
    const store = fakeStore();
    let spawnFnCalled = false;
    const spawnFn = () => { spawnFnCalled = true; return new FakeChild(); };
    const spawner = new AgentSpawner({ store, repoRoot: 'C:\\repo', spawnFn, claudeExecutable: FAKE_CLAUDE_EXE });
    const r = await spawner.spawn({ department: 'backend', task: 'x', permissionMode: 'sudo-everything' });
    assert.strictEqual(r.ok, false);
    assert.ok(/invalid permissionMode/.test(r.error));
    assert.strictEqual(spawnFnCalled, false);
  });

  // ---- resolveClaudeExecutable smoke test (real filesystem, no mocking) ----
  await test('resolveClaudeExecutable returns a real, existing path on this machine (or "claude" on non-Windows)', async () => {
    const fs = require('fs');
    const resolved = resolveClaudeExecutable();
    if (process.platform === 'win32') {
      assert.ok(resolved, 'expected a resolved path on Windows, got null — claude CLI may not be installed as expected');
      assert.ok(resolved.toLowerCase().endsWith('.exe'), `expected a .exe path, got: ${resolved}`);
      assert.ok(fs.existsSync(resolved), `resolved path does not exist on disk: ${resolved}`);
    } else {
      assert.strictEqual(resolved, 'claude');
    }
  });

  // ---- report ----
  const failed = results.filter((r) => !r.pass);
  console.log('\n=== agent-spawner.test.js RESULTS ===');
  for (const r of results) {
    console.log(`${r.pass ? 'PASS' : 'FAIL'} — ${r.name}${r.pass ? '' : `\n     ${r.detail}`}`);
  }
  console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
  process.exit(failed.length ? 1 : 0);
}

main();
