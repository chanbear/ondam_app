'use strict';

const { spawn: nodeSpawn, execFile, execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { readAgentRoster } = require('./config-reader');

const VALID_DEPARTMENTS = new Set(['management', 'senior', 'guardian', 'frontend', 'backend', 'qa', 'docs']);

// `claude --help`'s own documented choices for --permission-mode. Whitelisted
// here so an override (see spawn()'s `permissionMode` param) can never be an
// arbitrary string, even though — unlike `department`/`task` — this
// parameter is never read from the public HTTP spawn API (server.js's route
// does not forward it), only from direct, code-level invocation by a human
// who has explicitly approved relaxing the 'plan' default for one batch of
// spawns (Agent Workforce v2, Phase 8 Backend/Guardian: 2026-08-14 — see
// that day's decision to allow real file writes for those two department
// spawns only, reverting to 'plan' for everything else/afterward).
const VALID_PERMISSION_MODES = new Set(['acceptEdits', 'auto', 'bypassPermissions', 'manual', 'dontAsk', 'plan']);

// Per-department file-scope boundaries (Agent Workforce v2 §8 "파일 충돌
// 방지") — injected into every spawned agent's system prompt so parallel
// department agents don't edit the same files. This is a *convention*
// enforced via the prompt, not a filesystem permission — nothing in this
// codebase can technically stop a plan-mode agent from reading outside its
// lane (plan mode only blocks autonomous writes/commands in the first
// place), but it keeps write conflicts from happening once a human approves
// a spawned agent's plan.
const DEPARTMENT_SCOPE = {
  management: { allowed: ['전체 (읽기 전용 검토 + 작업 분배 목적)'], forbidden: [] },
  senior: { allowed: ['apps/senior/**'], forbidden: ['apps/guardian/**', 'supabase/**', 'packages/design_system/**'] },
  guardian: { allowed: ['apps/guardian/**'], forbidden: ['apps/senior/**', 'supabase/**', 'packages/design_system/**'] },
  frontend: { allowed: ['packages/design_system/**'], forbidden: ['apps/senior/**', 'apps/guardian/**', 'supabase/**'] },
  backend: { allowed: ['supabase/**'], forbidden: ['apps/senior/**', 'apps/guardian/**', 'packages/design_system/**'] },
  qa: { allowed: ['(기본 read-only) apps/**/test/**, apps/**/android/**, apps/**/ios/** (검증용 실행만)'], forbidden: ['production 코드(lib/**) — Management 승인 없이는 수정하지 않음'] },
  docs: { allowed: ['docs/**'], forbidden: ['apps/**', 'packages/**', 'supabase/**'] },
};

function scopeLines(department) {
  const scope = DEPARTMENT_SCOPE[department];
  if (!scope) return '';
  const allowed = scope.allowed.map((p) => `  - ${p}`).join('\n');
  const forbidden = scope.forbidden.length
    ? scope.forbidden.map((p) => `  - ${p}`).join('\n')
    : '  (없음)';
  return `\n\nALLOWED (이 영역만 수정):\n${allowed}\n\nDO NOT MODIFY (다른 부서 담당 — 절대 수정 금지):\n${forbidden}\n\n담당 범위를 벗어난 변경이 필요하면 직접 수정하지 말고 Management에 보고하라.`;
}

const DEPARTMENT_PROMPTS = {
  management: `너는 ONDAM 프로젝트의 Management(Lead/Architecture) 담당이다. 직접 대규모 코드를 수정하기보다 Architecture 검토, 작업 분배, 충돌 탐지, Phase 진행 관리, 다른 Agent 작업 결과 검토를 담당한다.${scopeLines('management')}`,
  senior: `너는 ONDAM 프로젝트의 Senior App(apps/senior) 담당이다. Senior UI/UX 및 기능 구현을 담당하며, 관련 문서를 먼저 읽고 작업한다.${scopeLines('senior')}`,
  guardian: `너는 ONDAM 프로젝트의 Guardian App(apps/guardian) 담당이다. Guardian UI/UX 및 보호자 기능 구현을 담당한다.${scopeLines('guardian')}`,
  frontend: `너는 ONDAM 프로젝트의 Frontend/UI(공통 Design System) 담당이다. 토큰화, 재사용성, 접근성, 컴포넌트화를 우선한다. Senior/Guardian feature 내부 UI를 직접 수정해야 하면 Management의 명시적 범위 지정을 먼저 받는다.${scopeLines('frontend')}`,
  backend: `너는 ONDAM 프로젝트의 Backend(Supabase) 담당이다. migration/RLS/Edge Function/Database/data model을 다루며 보안 규칙을 최우선으로 한다.${scopeLines('backend')}`,
  qa: `너는 ONDAM 프로젝트의 QA 담당이다. 기존 구현을 먼저 검증한다(flutter analyze/test/build, architecture 규칙, regression). 가짜 테스트 성공을 만들지 않는다. production 코드는 기본적으로 수정하지 않는다 — 문제 발견 시 (1)문제 보고 (2)원인 분석 (3)담당 부서 전달 (4)Management 보고 순으로 처리하고, Management 승인이 있을 때만 직접 수정한다.${scopeLines('qa')}`,
  docs: `너는 ONDAM 프로젝트의 Documentation 담당이다. architecture.md/technical-decisions.md/implementation-plan.md/feature-spec.md/ui-spec.md/agent-workforce.md를 실제 코드 상태에 맞게 유지한다. 코드와 문서가 불일치하면 보고한다. 존재하지 않는 기능을 문서화하지 않는다.${scopeLines('docs')}`,
};

const COMMON_SYSTEM_PROMPT = [
  '너는 ONDAM 프로젝트의 실제 개발팀 구성원이다.',
  '프로젝트 Repository의 기존 Architecture와 문서를 먼저 읽는다. 기존 구현을 존중하고 임의로 Architecture를 변경하지 않는다.',
  '작업 전에 현재 상태를 확인한다. 가짜 데이터로 성공을 위장하지 않는다. 테스트 가능한 변경은 테스트한다.',
  '완료되지 않은 작업을 완료했다고 보고하지 않는다.',
  '작업 종료 시 다음 형식으로 보고한다: 작업 내용 / 변경 파일 / 테스트 결과 / 미완료 사항 / Known Issues / 다음 작업.',
].join('\n');

const MAX_TASK_LENGTH = 4000;
const SAFE_MAX_BUDGET_USD = '2'; // hardcoded ceiling per spawned agent — not exposed to the web form
const DUPLICATE_WINDOW_MS = 5000;
const CONFIRM_TIMEOUT_MS = 15000; // max wait for the CLI's own "backgrounded · <id> ·" confirmation line
// eslint-disable-next-line no-control-regex
const CONTROL_CHAR_RE = /[\x00-\x08\x0b\x0c\x0e-\x1f]/;
// Kept as defense-in-depth even under shell:false (see resolveClaudeExecutable
// doc comment) — a denylist on the task text costs nothing and the project's
// own shell-injection regression tests (agent-spawner.test.js) assert on it.
const DANGEROUS_ARGV_CHARS_RE = /[&|<>^%`"\r\n]/;

const BACKGROUNDED_LINE_RE = /backgrounded[^\n]*?\b([0-9a-f]{6,})\b/i;
const SHORT_ID_RE = /^[0-9a-f]{6,}$/i;

// Statuses that mean "this desk is occupied" for the purpose of rejecting a
// duplicate same-department spawn (Agent Workforce v2 §9). COMPLETED/FAILED/
// UNKNOWN are NOT occupied — a finished or vanished agent must never block a
// new one.
const OCCUPIED_STATUSES = new Set(['WORKING', 'WAITING', 'REVIEWING', 'BLOCKED']);

/**
 * Resolves which roster department a real, currently-live agent belongs to.
 * Deliberately mirrors `public/app.js`'s `matchRosterEntry()` (kind +
 * nameContains, first roster entry wins) — this tool has no bundler/shared-
 * module system for browser JS, so the two copies are independent by
 * necessity. Keep them in sync manually if the matching rule ever changes.
 */
function matchDepartmentForAgent(agent, roster) {
  for (const entry of roster) {
    const m = entry.match || {};
    if (m.kind && agent.rawKind === m.kind) return entry;
    if (Array.isArray(m.nameContains) && agent.name) {
      const lower = agent.name.toLowerCase();
      if (m.nameContains.some((s) => lower.includes(String(s).toLowerCase()))) return entry;
    }
  }
  return null;
}

/**
 * Resolves the real `claude` executable to spawn directly with `shell:false`.
 *
 * Investigated live on 2026-08-13 (Claude Code 2.1.229, Windows, this
 * machine) per the "추측하지 않는다" requirement — nothing here is guessed:
 *   - `Get-Command claude -All` shows THREE PATH entries: `claude.ps1`,
 *     `claude.cmd`, and a third extensionless `claude` file, all living in
 *     the npm global root (e.g. `%APPDATA%\npm\`). All three are thin shims
 *     that exec `<npm-global>\node_modules\@anthropic-ai\claude-code\bin\claude.exe`
 *     — a REAL native PE executable, not a script.
 *   - Spawning that `.exe` directly via `child_process.spawn(exe, argv,
 *     {shell:false})` was live-fire tested and works — no shell needed at
 *     all. This removes the entire class of Windows shell-metacharacter/
 *     quoting risk that `shell:true` carried, satisfying the "shell:false
 *     wherever possible" requirement for real (not just "argv array under
 *     shell:true", which was the previous, weaker mitigation).
 *   - On non-Windows platforms, `claude` installed via npm is normally a
 *     real executable or a direct symlink to one — no `.cmd`/`.ps1` shim
 *     layer exists there, so no resolution is needed; spawn the bare
 *     command with `shell:false` directly.
 *
 * Returns `null` if resolution fails (binary not found under the expected
 * layout) — callers MUST treat that as a hard failure and report it, never
 * silently fall back to `shell:true`.
 */
function resolveClaudeExecutable() {
  if (process.platform !== 'win32') return 'claude';
  try {
    const whereOut = execFileSync('where', ['claude'], { windowsHide: true, encoding: 'utf8' });
    const candidates = whereOut
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean);
    for (const candidate of candidates) {
      const npmRoot = path.dirname(candidate);
      const exe = path.join(npmRoot, 'node_modules', '@anthropic-ai', 'claude-code', 'bin', 'claude.exe');
      if (fs.existsSync(exe)) return exe;
    }
  } catch (_err) {
    // `where` itself failed (claude not on PATH at all) — fall through to null.
  }
  return null;
}

/**
 * Spawns a real `claude --bg` background session per Office department.
 *
 * Safety properties (see docs/agent-workforce.md "Spawn safety defaults" —
 * this class doc supersedes the pre-2026-08-13 (later revision) description
 * there of session-id pre-generation and `shell:true`, both since replaced):
 *  - `shell:false`, always — see `resolveClaudeExecutable()` above. The task
 *    text is one argv array element, never concatenated into a command
 *    string, so there is no shell to inject into in the first place. The
 *    `DANGEROUS_ARGV_CHARS_RE` denylist is kept anyway as defense-in-depth
 *    and because the project's shell-injection regression tests assert on
 *    it — belt-and-suspenders, not load-bearing on its own anymore.
 *  - CHANGED 2026-08-13 (second live-fire round): `--session-id` is no
 *    longer sent. Live testing showed `claude --bg` prints
 *    `warning: --bg manages the session id; ignoring --session-id` — this
 *    CLI version always assigns its own id for backgrounded sessions.
 *    Instead, the real id is read from `--bg`'s own stdout confirmation
 *    line (`backgrounded · <id> · <name>`), which this class waits for
 *    (bounded by `CONFIRM_TIMEOUT_MS`) before resolving `spawn()`'s promise.
 *    This is a *stronger* correctness property than the old pre-generated
 *    UUID approach — the id is CLI-confirmed truth, not a guess that a
 *    later poll had to match up.
 *  - `spawn()` is therefore now `async` and returns a Promise, not a plain
 *    object — callers must `await` it. Validation failures still resolve
 *    (near-)synchronously (no process is ever spawned for those).
 *  - `--permission-mode plan` is hardcoded: a spawned agent investigates and
 *    proposes a plan, it does not autonomously edit files or run commands.
 *    Deliberate first-implementation safety default — see Known limitations.
 *  - `--max-budget-usd` caps spend per spawned agent; not user-configurable.
 *    NOTE: `claude --help` documents this flag as "(only works with
 *    --print)" — live testing shows it does NOT error when combined with
 *    `--bg` (no `-p`), but this dashboard has not verified it is actually
 *    *enforced* in that mode (would require a real overrun to prove either
 *    way, which this project will not do just to test a limit). Treat it as
 *    unverified-but-harmless, not a proven hard cap, until confirmed
 *    otherwise — recorded honestly in Known limitations rather than assumed.
 *  - `cwd` is always the dashboard's own repo root — never derived from
 *    request input, so there is no path to traverse.
 *  - CHANGED 2026-08-13 (second live-fire round): a real, documented `claude
 *    stop <id>` command exists and works (confirmed live: process
 *    terminates, `claude agents --json --all` then reports
 *    `"state": "stopped"`, and the session disappears from the default
 *    (non-`--all`) listing exactly like a natural completion). The previous
 *    "no safe stop exists" limitation was wrong for this CLI version — a
 *    stop endpoint is a legitimate follow-up now, but wiring an office-wide
 *    "중단" button is out of scope for *this* change (single Management
 *    spawn validation only, per instruction) and is left as a Known
 *    limitation/next step rather than built speculatively.
 */
class AgentSpawner {
  constructor({
    store,
    repoRoot,
    spawnFn = nodeSpawn,
    execFileFn = execFile,
    claudeExecutable = null,
    resolveExecutable = resolveClaudeExecutable,
    loadRoster = null,
  }) {
    this.store = store;
    this.repoRoot = repoRoot;
    this.spawnFn = spawnFn; // injectable for tests — never mocked in production wiring
    this.execFileFn = execFileFn; // injectable for tests — used by stop()
    // Injectable for tests (bypasses resolution entirely with a fixed path).
    this._claudeExecutable = claudeExecutable;
    // Also injectable for tests, independent of `claudeExecutable` above —
    // lets a test force a resolution *failure* (returns null) deterministically,
    // without depending on this machine's real filesystem/PATH.
    this._resolveExecutable = resolveExecutable;
    // Injectable for tests — defaults to the real config/agents.json reader.
    this._loadRoster = loadRoster || (() => readAgentRoster(this.repoRoot).roster || []);
    this.pending = new Map(); // internal requestId -> { department, requestedAt, name }
  }

  /**
   * True if a REAL, currently-live agent (per the store's latest
   * `claude agents --json` poll) is already occupying this department
   * (Agent Workforce v2 §9: "Senior Agent가 이미 WORKING이면 새 Senior Agent
   * spawn 요청 → 거부"). Distinct from the `pending`-map debounce below,
   * which only catches a "double click" race in the few seconds before a
   * spawn confirms — this catches a fully-registered agent that has been
   * working for any length of time.
   */
  isDepartmentBusy(department) {
    const agents = (this.store.state && this.store.state.agents) || [];
    if (!agents.length) return false;
    const roster = this._loadRoster();
    return agents.some((agent) => {
      if (!OCCUPIED_STATUSES.has(agent.status)) return false;
      const entry = matchDepartmentForAgent(agent, roster);
      return !!entry && entry.department === department;
    });
  }

  /** Pure validation, no side effects — used directly by tests. */
  validate({ department, task, name }) {
    if (typeof department !== 'string' || !VALID_DEPARTMENTS.has(department)) {
      return { ok: false, error: `invalid department: ${JSON.stringify(department)}` };
    }
    if (typeof task !== 'string' || !task.trim()) {
      return { ok: false, error: 'task is required' };
    }
    if (CONTROL_CHAR_RE.test(task)) {
      return { ok: false, error: 'task contains invalid control characters' };
    }
    if (DANGEROUS_ARGV_CHARS_RE.test(task)) {
      return {
        ok: false,
        error: 'task contains characters not allowed as a command-line argument (& | < > ^ % ` " or newlines) — rephrase without these',
      };
    }
    if (task.length > MAX_TASK_LENGTH) {
      return { ok: false, error: `task too long (max ${MAX_TASK_LENGTH} chars)` };
    }
    // `name` goes on the command line (`--name <name>`) — restricted to a
    // safe charset as defense in depth regardless of shell:false.
    if (name !== undefined) {
      if (typeof name !== 'string' || !/^[a-zA-Z0-9_-]{1,80}$/.test(name)) {
        return { ok: false, error: 'name must be 1-80 chars of letters, digits, "-", "_" only' };
      }
    }
    const recentSameDept = [...this.pending.values()].some(
      (p) => p.department === department && Date.now() - p.requestedAt < DUPLICATE_WINDOW_MS,
    );
    if (recentSameDept) {
      return { ok: false, error: '같은 부서에 대한 출근 요청이 이미 처리 중입니다. 잠시 후 다시 시도하세요.' };
    }
    if (this.isDepartmentBusy(department)) {
      return { ok: false, error: `${department} 부서에 이미 근무 중인 Agent가 있습니다. 완료되거나 퇴근시킨 뒤 다시 시도하세요.` };
    }
    return { ok: true };
  }

  /**
   * Stops a real background session via `claude stop <shortId>` (confirmed
   * live: this command exists, only accepts the CLI's short 8-char id — NOT
   * the full UUID `sessionId`, tested both ways — and only works on
   * `kind:"background"` sessions).
   *
   * Security (Agent Workforce v2 §17): `sessionId` MUST already exist in
   * `store.state.agents` (the Office's own real, currently-observed roster)
   * — this is looked up here, not trusted from the caller, so an API caller
   * cannot supply an arbitrary id to stop a session outside the dashboard's
   * own view (e.g. an unrelated `claude` session on the same machine that
   * never showed up as an Office employee).
   *
   * @returns {Promise<{ok:true, sessionId:string, shortId:string} | {ok:false, error:string}>}
   */
  async stop(sessionId) {
    const agents = (this.store.state && this.store.state.agents) || [];
    const agent = agents.find((a) => a.sessionId === sessionId);
    if (!agent) {
      return { ok: false, error: '이 sessionId는 현재 AI Office에 등록된 실제 Agent가 아닙니다.' };
    }
    if (agent.rawKind !== 'background') {
      return { ok: false, error: 'interactive 세션은 이 기능으로 종료할 수 없습니다(claude stop은 background 세션 전용).' };
    }
    const shortId = agent.id;
    if (!shortId || !SHORT_ID_RE.test(shortId)) {
      return { ok: false, error: '이 Agent의 short id를 확인할 수 없습니다.' };
    }

    const claudeExecutable = this._claudeExecutable || this._resolveExecutable();
    if (!claudeExecutable) {
      const msg = 'claude 실행 파일을 찾지 못했습니다(resolveClaudeExecutable 실패) — CLI 설치 상태를 확인하세요.';
      this.store.addLog('spawn', msg, 'error');
      return { ok: false, error: msg };
    }

    return new Promise((resolve) => {
      this.execFileFn(
        claudeExecutable,
        ['stop', shortId],
        { cwd: this.repoRoot, shell: false, windowsHide: true },
        (err, stdout, stderr) => {
          if (err) {
            const msg = (stderr && stderr.trim()) || err.message;
            this.store.addLog('spawn', `claude stop ${shortId} failed: ${msg}`, 'error');
            resolve({ ok: false, error: msg });
            return;
          }
          this.store.addLog('spawn', `claude stop ${shortId} succeeded (${(stdout || '').trim()}) — waiting for the next poll to confirm removal`, 'info');
          resolve({ ok: true, sessionId, shortId });
        },
      );
    });
  }

  buildArgs({ department, task, name, permissionMode = 'plan', extraSystemPrompt = '' }) {
    const systemPrompt = `${COMMON_SYSTEM_PROMPT}\n\n${DEPARTMENT_PROMPTS[department]}${extraSystemPrompt ? `\n\n${extraSystemPrompt}` : ''}`;
    return [
      '--bg',
      task,
      '--name', name,
      '--permission-mode', permissionMode,
      '--max-budget-usd', SAFE_MAX_BUDGET_USD,
      '--append-system-prompt', systemPrompt,
    ];
  }

  /**
   * @param {object} opts
   * @param {string} [opts.permissionMode] — defaults to 'plan' (investigate/
   *   propose only). NEVER sourced from the public HTTP spawn API — only a
   *   direct, code-level caller can request a different mode, and only one
   *   of `VALID_PERMISSION_MODES`. This is how the Phase 8 Backend/Guardian
   *   "실제로 코드를 작성하게 한다" approval is applied without loosening the
   *   default for every future spawn or for web-form-driven requests.
   * @param {string} [opts.extraSystemPrompt] — appended after the department
   *   prompt for this call only (e.g. extra commit/push prohibitions for an
   *   elevated-permission batch) — never persisted into DEPARTMENT_PROMPTS.
   * @returns {Promise<{ok:true, sessionId:string, name:string, department:string} | {ok:false, error:string}>}
   */
  async spawn({ department, task, name: requestedName, permissionMode = 'plan', extraSystemPrompt = '' }) {
    const validation = this.validate({ department, task, name: requestedName });
    if (!validation.ok) return validation;
    if (!VALID_PERMISSION_MODES.has(permissionMode)) {
      return { ok: false, error: `invalid permissionMode: ${JSON.stringify(permissionMode)}` };
    }

    const claudeExecutable = this._claudeExecutable || this._resolveExecutable();
    if (!claudeExecutable) {
      const msg = 'claude 실행 파일을 찾지 못했습니다(resolveClaudeExecutable 실패) — CLI 설치 상태를 확인하세요.';
      this.store.addLog('spawn', msg, 'error');
      return { ok: false, error: msg };
    }

    const requestId = crypto.randomUUID();
    const name = requestedName || `ondam-office-${department}-${Date.now()}`;
    const args = this.buildArgs({ department, task, name, permissionMode, extraSystemPrompt });
    if (permissionMode !== 'plan') {
      this.store.addLog('spawn', `⚠ ${department} agent "${name}" spawning with ELEVATED permission-mode="${permissionMode}" (not the default 'plan') — human-approved for this batch only`, 'info');
    }

    let child;
    try {
      child = this.spawnFn(claudeExecutable, args, {
        cwd: this.repoRoot,
        shell: false,
        windowsHide: true,
        stdio: ['ignore', 'pipe', 'pipe'],
      });
    } catch (err) {
      return { ok: false, error: err.message };
    }

    this.pending.set(requestId, { department, requestedAt: Date.now(), name });
    this.store.addLog('spawn', `Requested: ${department} agent "${name}" — launching claude --bg (shell:false)`, 'info');

    let stdout = '';
    let stderrTail = '';

    return new Promise((resolve) => {
      let settled = false;
      const finish = (result) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        this.pending.delete(requestId);
        resolve(result);
      };

      const timer = setTimeout(() => {
        this.store.addLog(
          'spawn',
          `Timed out waiting for ${name} to confirm a background session id within ${CONFIRM_TIMEOUT_MS}ms`,
          'error',
        );
        finish({ ok: false, error: '스폰 확인 시간 초과 — claude CLI가 백그라운드 세션 확인 메시지를 보내지 않았습니다.' });
      }, CONFIRM_TIMEOUT_MS);

      child.on('error', (err) => {
        this.store.addLog('spawn', `Spawn process error for ${name}: ${err.message}`, 'error');
        finish({ ok: false, error: err.message });
      });

      const tryParseConfirmation = () => {
        const match = BACKGROUNDED_LINE_RE.exec(stdout);
        if (!match) return;
        const sessionId = match[1];
        this.store.addLog(
          'spawn',
          `Confirmed: ${department} agent "${name}" backgrounded as ${sessionId} — waiting for claude agents --json to show it`,
          'info',
        );
        finish({ ok: true, sessionId, name, department });
      };

      if (child.stdout) {
        child.stdout.on('data', (chunk) => {
          stdout += chunk.toString('utf8');
          tryParseConfirmation();
        });
      }
      if (child.stderr) {
        child.stderr.on('data', (chunk) => {
          stderrTail = (stderrTail + chunk.toString('utf8')).slice(-2000);
        });
      }

      // `--bg` is documented to detach and return quickly. If the process
      // closes before we ever saw the confirmation line, the *launch*
      // failed (this is not the agent's own later work failing — that
      // would show up as a real FAILED session in claude agents --json, if
      // it ever registered at all).
      child.on('close', (code) => {
        if (settled) return;
        this.store.addLog(
          'spawn',
          `claude --bg exited ${code} for ${name} before confirming a session id: ${stderrTail.trim()}`,
          'error',
        );
        finish({
          ok: false,
          error: `claude --bg exited ${code} without confirming a background session${stderrTail ? `: ${stderrTail.trim()}` : ''}`,
        });
      });
    });
  }
}

module.exports = {
  AgentSpawner,
  VALID_DEPARTMENTS,
  MAX_TASK_LENGTH,
  SAFE_MAX_BUDGET_USD,
  resolveClaudeExecutable,
  matchDepartmentForAgent,
  OCCUPIED_STATUSES,
};
