# ONDAM Engineering Command Center

A local dashboard that shows the **real, currently observable** state of Claude Code sessions, git, and the project's own test/build commands for this repo — not a mockup with placeholder data.

## Run it

```
node tools/agent-dashboard/server.js
```

(from the repo root — no `npm install` needed, zero external dependencies). Or from inside this directory: `npm start`. It prints the URL it bound to (auto-picks a free port starting at 4500, tries up to 20 ports up).

## What's actually connected, and how

The **only** officially documented, scriptable Claude Code interface this Bridge uses is:

```
claude agents --json           # all sessions on this machine
claude agents --json --cwd X   # sessions scoped to directory X
claude --version                # availability check
```

`claude agents --help` documents `--json` as: *"Print active sessions (interactive and background) as a JSON array and exit (for scripting; does not require a TTY)."* This is the sole source of Agent data. Everything else in the dashboard (git, tests, docs) is sourced directly and independently — not through Claude Code.

**Deliberately not used**: the undocumented `~/.claude/projects/*/​*.jsonl` session transcript files that Claude Code happens to write to disk. They exist and are readable, but they're internal storage, not a supported interface, and reading them would violate the "don't guess at internal files/private APIs" ground rule this dashboard was built under.

### Confirmed available (real data)

- Session list, `kind` (interactive/background), `status`/`state`, `sessionId`, `pid` (interactive only), `cwd`, `startedAt` — straight from `claude agents --json`.
- Git branch/commit/working-tree status/recent commits — straight from `git`, for this repo.
- Test results — straight from `flutter analyze`/`flutter test`/`flutter build apk --debug`, run for real when you click a button, never automatically.
- Project phase status — parsed from `docs/product/implementation-plan.md`'s actual `### Phase N` headers at request time.
- Architecture tab's app/package list — a real `fs.readdirSync` of `packages/` and existence checks for `apps/senior`/`apps/guardian`.
- A session's git branch (shown on Agent cards) — real `git rev-parse` run against that session's own `cwd`. This is genuine git data about that directory, **not** something Claude Code reported — labelled "(from git, not Claude Code)" in the UI so it's never mistaken for a Claude-provided field.

### Confirmed NOT available (rendered as "Unavailable" / "Not exposed" / "UNKNOWN", never fabricated)

- **Per-session live tool activity** ("Read file X", "Running flutter test") — Claude Code's CLI exposes no such log to external processes. The Activity feed you see by default is built entirely from *observed state transitions* during polling (session appeared, status changed, session disappeared) — never simulated/periodic filler.
- **Progress percentage** — no such field exists anywhere in `claude agents --json`. Always `null` client-side; UI always renders "Progress unavailable", never an invented number.
- **Agent role/type** ("QA Agent", "Backend Agent", etc.) — not exposed. The UI falls back to "Claude Code Agent" + the session's real `name` field (a real, user/agent-set session label — not a live task description) or `Session <id>` if unnamed.
- **A real task queue / kanban backlog** — Claude Code exposes no such API. The Tasks tab's BACKLOG and REVIEW columns are explicitly left empty with a note saying so; IN PROGRESS/BLOCKED/DONE are populated from real, currently-observed session states, not invented tickets. The static Phase plan is shown in a visually separate "Project Plan" panel so it's never confused with this live board.
- **Tool names used per session**, unless you opt into the hook below — then this becomes real, tool-name-level data for sessions running in this project only.

### Optional: richer activity via a hook (not installed by default)

`hooks/dashboard-activity-hook.js` is a ready-to-use, opt-in Claude Code `PostToolUse` hook. It reads the documented hook JSON payload from stdin (`session_id`, `tool_name`, `tool_input`, ...), extracts only a short generic summary (tool name + a filename/command-name hint — **never** full tool input, since that could contain file contents or secrets), and appends one redacted line to `data/hook-activity.jsonl`, which `agent-monitor.js` tails.

This dashboard does **not** install it for you — it would change how every Claude Code session in this project behaves (an extra command runs on every tool call), which isn't something a dashboard should do silently. To enable it: merge `hooks/settings.snippet.json`'s `hooks.PostToolUse` entry into your own **project-level** `.claude/settings.json` (create it if it doesn't exist), replacing `<REPO_ROOT>` with this repo's absolute path. It's additive — it does not touch or disable any existing hooks (including unrelated user-level ones already configured on this machine).

Without the hook: Agent cards show real but coarse activity (status transitions only). With it: real per-tool-call entries for sessions in this project, tagged `source: "hook"` vs `source: "claude"` in the API so the UI (and you) can always tell which is which.

## Security

- The Bridge process never reads `.env`, Claude Code credential/auth files, or any Supabase key — there is nothing to leak because it's never loaded, not just "redacted after the fact."
- Every log line and activity string is additionally passed through a redaction filter (`state-store.js`'s `redact()`) before being stored or sent to the browser — catches JWT-shaped strings, `sk-`/`gh*_`/`sbp_`-style API keys, `Bearer` tokens, `KEY=`/`SECRET=`/`TOKEN=`/`PASSWORD=`/`PIN=`-style assignments, and Korean phone numbers (middle digits masked) — as defense in depth against secrets that might appear incidentally in git commit messages, test output, or session names.
- The optional hook never logs full tool input, only a generic descriptor.

## Known limitations

- Claude Code's session `name` field is a real, user/agent-set label, but it is **not** a live description of what the session is doing *right now* — treat it as a title, not a status line.
- `status`/`state` enum values `idle` (interactive) and `running` (background) are inferred from the CLI's own field naming, not yet observed live on this machine — the code treats any unrecognized value as `UNKNOWN` rather than crashing, so this is safe either way.
- "Last observed change" timestamps reflect when *this dashboard's polling* noticed a change (every ~2.5s), not a timestamp Claude Code itself reports.
- No WebSocket — SSE only (one-directional server→browser push; actions go through plain POST). This was a deliberate simplicity/robustness choice, not a limitation of what's possible.
- This dashboard was built and verified from an isolated git worktree, so during its own build/verification the Agents tab legitimately showed 0 "project" agents and 3 "other" sessions (the worktree's own `cwd` differs from the main repo's) — that's the `--cwd` scoping working exactly as intended, not a bug. Run it from the main checkout for it to bucket the live coordinator session as "this project."

## ONDAM Office — Agent Workforce (config/agents.json)

The Office tab (default landing view) renders each **real, currently-connected** Claude Code session (`state.agents`, scoped to this project) as a pixel employee. `config/agents.json` is a small, user-editable *display* registry — it never supplies agent data itself, only a suggested department/role label and a name/kind hint used to recognize a real session:

```json
{ "roster": [
  { "id": "backend-01", "department": "backend", "role": "Supabase / Backend Engineer",
    "displayName": "Backend Engineer", "match": { "nameContains": ["backend"] } }
]}
```

- Served read-only via `GET /api/config/agents` (`config-reader.js`, re-read on every request — edit the file and the Office tab picks it up within 30s, no restart needed for this file; a `server.js` change does need a restart).
- Matching: `match.kind` compares against the session's real `rawKind` (`interactive`/`background`); `match.nameContains` does a case-insensitive substring check against the session's real `name`. First matching roster entry wins. A manual per-session override (the employee detail panel's department dropdown, stored in `localStorage`) always takes priority over an automatic roster match.
- A roster entry with **no matching real session is rendered as a dim, sleeping "미출근" desk** — never as a working employee. Department room headers show `현재 연결됨 / roster 정원` (e.g. `1 / 1명`) computed from real matches only; if a department has no roster entries at all, only a plain headcount is shown (no invented target).
- An 👑 badge marks a session whose real `rawKind === "interactive"` — that's genuine Claude Code data (foreground vs. background), not a claimed "leader" role.
- Agent spawning (`claude -p "..." --bg` is a real, documented capability) is **not** wired to a UI button yet — deliberately deferred, see Known limitations.

See `docs/agent-workforce.md` for the full Agent → Employee → Office data-flow writeup.

## Agent Spawn ("+ 직원 출근시키기")

`POST /api/agents/spawn` (`agent-spawner.js`) launches a **real** `claude -p --bg` process — department is whitelisted, task text is delivered over the child's stdin (never argv/shell), `--session-id` is pre-generated so the resulting real session can be matched with certainty, `--permission-mode plan` and `--max-budget-usd 2` are hardcoded safety defaults, and `cwd` is always this repo root. There is no "stop" endpoint — `claude agents --help` exposes no documented way to end a specific background session and background sessions don't expose a `pid`, so killing one would mean guessing a process to terminate. Full design rationale, safety table, and Known limitations: `docs/agent-workforce.md`. Tests: `node tools/agent-dashboard/agent-spawner.test.js` (never spawns a real process — injects a fake `spawnFn`).

## Files

```
tools/agent-dashboard/
  server.js            HTTP + SSE server, routes, port auto-pick
  claude-adapter.js     `claude agents --json` / `--version` wrapper — the only file that knows about the Claude CLI
  agent-monitor.js       polls the adapter, normalizes to Agent shape, diffs for real activity
  git-monitor.js          git branch/commit/status/log wrapper
  test-runner.js           on-demand flutter analyze/test/build runner
  docs-reader.js           parses docs/product/implementation-plan.md phases + real dir listing for Architecture
  config-reader.js         parses config/agents.json (Office department/role display registry)
  state-store.js           central store, SSE fan-out source, log ring buffer, redaction
  config/
    agents.json            user-editable roster — department/role labels + name/kind match hints
  hooks/
    dashboard-activity-hook.js   optional PostToolUse hook (not auto-installed)
    settings.snippet.json         example wiring for your own .claude/settings.json
  data/                     hook-activity.jsonl lands here if you enable the hook
  public/
    index.html / app.js / styles.css   the dashboard UI (vanilla JS, no build step) — Office tab is the default view
  package.json
```

---

# Final Report

## Dashboard
- 경로: `tools/agent-dashboard/`
- 실행 명령: `node tools/agent-dashboard/server.js` (repo root 기준, 설치 단계 없음)
- URL: 실행 시 콘솔에 출력됨 (기본 `http://localhost:4500`, 사용 중이면 자동으로 다음 포트 탐색)

## Claude Code Connection
- 실제 연결 여부: 예 — `claude agents --json`(공식 문서화된 스크립팅 인터페이스, `claude agents --help`에 명시)로 실시간 세션 목록을 가져옴
- 사용한 공식/지원 방식: `claude agents --json` / `--all` / `--cwd` / `claude --version`
- 확인 가능한 정보: session id, kind(interactive/background), status/state, cwd, startedAt, pid(interactive), name(세션 라벨)
- 확인 불가능한 정보: 세션별 실시간 tool 사용 로그(옵션 hook 없이는 미노출), progress %, agent role/type, 실제 task queue — 전부 UI에 "Unavailable"/"Not exposed"로 명시, 임의 생성 없음

## Agent Monitoring
- Agent detection: 실동작 확인 — 이 저장소를 기준(`--cwd`)으로 스코프된 세션 + 머신 전체 세션(별도 구획)을 실시간 폴링(2.5초)
- Status: `claude agents --json`의 `status`/`state`를 WORKING/WAITING/BLOCKED/COMPLETED/FAILED/UNKNOWN으로 매핑(관찰되지 않은 값은 안전하게 UNKNOWN 처리)
- Activity: 폴링에서 실제 관찰된 상태 변화만 기록(가짜/주기적 activity 없음) + 선택적 hook으로 실제 tool 단위 활동 보강 가능
- Logs: Bridge/Claude/Agent/Git/Test 소스별로 태깅되어 저장, 최근 150개 SSE로 전달 + `/api/state`로 스냅샷 조회

## Git
- Branch: 실제 `git rev-parse --abbrev-ref HEAD` — 메인 저장소 재검증 시점 `master`
- Commit: 실제 `git rev-parse --short HEAD` — 메인 저장소 재검증 시점 `f9cdd23`(이후 Phase 6 커밋 전이라 동일)
- Working tree: 실제 `git status --porcelain` 파싱 결과(staged/modified/untracked 카운트 + clean 여부) — Phase 6 작업으로 dirty 상태였음을 정확히 반영

## Tests
- Dashboard tests: `/api/state`, `/events`(SSE hello), `/api/tests/run`(정상 거부 확인, 실제 flutter 프로세스는 이번 검증에서 실행하지 않음 — 동시에 진행 중인 Phase 6 Flutter/Gradle 작업과의 메모리 경합을 피하기 위해 의도적으로 생략), `/api/agents/:id`(404 확인) 모두 정상 동작 확인
- Integration tests: 서버 기동 → 실제 포트 바인딩 → `/api/state`가 실제 git/claude/docs 데이터를 반환 → SSE로 동일 스냅샷 전달 → 정상 종료(프로세스 kill)까지 end-to-end 확인. `flutter analyze`/`test`/`build`는 버튼 클릭 시에만 동작하도록 구현했고 실제 트리거는 검증 범위에서 제외(위 사유)

## Security
- Secret exposure: 없음 — Bridge는 `.env`/Claude 인증 파일/Supabase 키를 아예 읽지 않음
- Masking: 로그/활동 문자열 전체에 JWT형/`sk-`/`gh*_`/`sbp_`/`Bearer`/`KEY=`류/한국 전화번호 패턴 redaction 적용(방어적 2중 장치)

## Known Limitations
- Claude Code CLI가 세션별 실시간 tool 활동을 노출하지 않음 — opt-in hook 없이는 상태 전이 수준 activity만 제공
- `idle`(interactive)/`running`(background) 상태값은 이 머신에서 실관찰되지 않고 CLI 필드 네이밍에서 추론한 값 — 안전하게 처리되지만 명시적으로 문서화함
- "Last observed change"는 Claude Code가 보고한 시각이 아니라 이 대시보드의 폴링이 변화를 감지한 시각
- 실제 task queue API 없음 — Task Board는 실제 세션 상태를 컬럼에 매핑한 것이지 진짜 작업 추적 시스템이 아님(README/UI에 명시)
- 원래 이 대시보드는 격리된 git worktree에서 구현·1차 검증됐다(그 시점엔 Agents 탭이 "이 프로젝트" 0개로 보였다 — worktree의 cwd가 메인 저장소와 달라 `--cwd` 스코핑이 의도대로 작동한 것). 이후 메인 작업 디렉터리로 병합하고 재검증했다 — 아래 "메인 저장소 재검증" 참고.
- 재검증 중 폴링 겹침(overlap) 버그를 발견해 수정했다: `_tick()`이 (child_process 2회 + git 브랜치 조회로) `pollIntervalMs`(2.5초)보다 오래 걸리면 다음 타이머가 겹쳐 실행되어 "Session detected"가 같은 세션에 대해 여러 번 기록됐다. `agent-monitor.js`에 in-flight 가드(`_ticking`)를 추가해 겹치는 tick을 건너뛰도록 고쳤고, 8초(2회 이상의 폴링 주기) 동안 activity가 정확히 1건만 기록되는 것을 재확인했다.

### 메인 저장소 재검증 (worktree 병합 후)
- `node tools/agent-dashboard/server.js`를 메인 작업 디렉터리에서 직접 실행 → `claudeAvailable: true`, `claudeVersion: "2.1.229 (Claude Code)"` 확인.
- `agents` 배열에 **이 대화 세션 자체**가 실제로 잡혔다: `name: "ondam-app-master-79"`, `status: WORKING`(원본 `status: "busy"`), `pid: 17344`, `cwd`가 메인 저장소 경로와 일치, `inProject: true`, `branch: "master"`(해당 세션 cwd에 대해 실행한 `git rev-parse` 결과).
- `otherSessions`에 이 머신의 무관한 다른 프로젝트 세션 2개가 별도로 분리되어 표시됨(합쳐서 노출하지 않음).
- `git` 스냅샷: `branch: "master"`, 실제 커밋 해시/메시지, `staged/modified/untracked` 실제 카운트 — 전부 메인 저장소 기준 실값으로 확인.
- `project.currentPhase`: Phase 6 완료 문서 반영 직후 재요청한 결과 **"Phase 7 — 문자/위험 기능(Android 전용)", status: READY**로 정확히 갱신됨 — `docs/product/implementation-plan.md`를 그때그때 다시 읽어 파싱한다는 것을 실증.
- 검증 후 프로세스 정상 종료(포트 반납 확인).

## Files Created
- `tools/agent-dashboard/server.js`
- `tools/agent-dashboard/claude-adapter.js`
- `tools/agent-dashboard/agent-monitor.js`
- `tools/agent-dashboard/git-monitor.js`
- `tools/agent-dashboard/test-runner.js`
- `tools/agent-dashboard/docs-reader.js`
- `tools/agent-dashboard/state-store.js`
- `tools/agent-dashboard/hooks/dashboard-activity-hook.js`
- `tools/agent-dashboard/hooks/settings.snippet.json`
- `tools/agent-dashboard/public/index.html`
- `tools/agent-dashboard/public/app.js`
- `tools/agent-dashboard/public/styles.css`
- `tools/agent-dashboard/package.json`
- `tools/agent-dashboard/README.md`
- `tools/agent-dashboard/data/` (empty until the optional hook is enabled)

실행 명령: `node tools/agent-dashboard/server.js`
