# ONDAM Office — Agent Workforce

개발 도구 문서. `tools/agent-dashboard/`(픽셀아트 "ONDAM AI OFFICE")가 실제 Claude Code Agent를
어떻게 화면의 "직원"으로 시각화하는지 정리한다. ONDAM 앱(Senior/Guardian) 프로덕션 코드와는
무관하며, 이 문서는 그 대시보드 도구 자체의 아키텍처 문서다.

## 데이터 흐름

```
실제 Claude Code Agent (interactive/background 세션)
  ↓ claude agents --json  (claude-adapter.js — 공식 문서화된 유일한 스크립팅 인터페이스)
Agent Monitor (agent-monitor.js)
  — 2.5초 폴링, 상태를 WORKING/WAITING/REVIEWING/BLOCKED/COMPLETED/FAILED/UNKNOWN으로 정규화
  — 세션이 성공적인 poll에서 사라진 경우에만 "종료"로 간주 (일시적 API 실패는 이전 상태 유지)
  ↓
State Store (state-store.js) → SSE(/events) + REST(/api/state)
  ↓
브라우저 app.js
  — state.agents(이 프로젝트) 각각을 config/agents.json roster와 매칭(department/role 라벨)
  — 매칭 안 되면 "오픈 오피스"(미배정)로, 실제 Claude 데이터는 그대로 유지
  ↓
Office 화면 (부서별 방 + 픽셀 직원 + 출퇴근 애니메이션)
```

이 흐름 중 "실제 데이터"인 것은 세션 목록/상태/이름/kind/cwd/시작시각뿐이다.
부서/역할/캐릭터 외형은 전부 표시(presentation)용이며 Claude Code가 제공하는 값이 아니다.

## Agent ↔ Employee 매칭

`config/agents.json`의 `roster[]` 각 항목:

| 필드 | 의미 |
|---|---|
| `id` | roster 항목 식별자 (부서당 정원 계산에 사용) |
| `department` | 소속시킬 부서 id (아래 부서 구조 참고) |
| `role` / `displayName` | 화면에 보여줄 라벨 — Claude Code가 준 값이 아니라 이 파일에서 사람이 정한 값 |
| `match.kind` | 세션의 실제 `rawKind`(`interactive`/`background`)와 비교 |
| `match.nameContains` | 세션의 실제 `name`(사용자/Agent가 붙인 세션 라벨)에 대한 대소문자 무시 부분일치 |

매칭 우선순위:

1. **수동 지정** — 직원 상세 패널의 부서 드롭다운(브라우저 `localStorage`에 세션ID 기준 저장)이 항상 최우선.
2. **Roster 자동 매칭** — 위 규칙으로 첫 번째로 매칭되는 roster 항목.
3. **미배정** — 어느 것도 매칭되지 않으면 "오픈 오피스"에 표시(세션 자체는 숨기지 않음 — 가짜 미배정 대신 실제로는 항상 화면에 보인다).

**roster 항목에 매칭되는 실제 세션이 없으면** 그 자리는 회색 "미출근"(💤) 상태로만 표시된다 —
WORKING으로 보이게 하거나 인원수를 부풀리지 않는다. 부서 헤더의 `N / T명` 표시에서 `T`(정원)는
그 부서에 정의된 roster 항목 개수, `N`(현재)은 실제로 매칭되어 연결된 세션 수다.

## 부서 구조

```
🏢 MANAGEMENT     — Lead / Architecture (기본 roster: interactive 세션과 매칭)
📱 SENIOR APP     — apps/senior 담당
👨‍👩‍👧 GUARDIAN APP  — apps/guardian 담당
🎨 FRONTEND / UI  — 디자인 시스템 / UI 작업
🗄️ BACKEND        — Supabase / migration / RLS / Edge Function
🧪 QA             — 테스트 / 회귀 / 아키텍처 검증
📚 DOCUMENTATION  — docs/ 갱신
🗂️ 오픈 오피스     — 어느 roster에도 매칭되지 않은 실제 세션 (항상 실제로 표시)
```

## 상태 매핑

Claude Code CLI가 실제로 노출하는 상태는 `agent-monitor.js`의 `STATUS` enum(WORKING/WAITING/
REVIEWING/BLOCKED/COMPLETED/FAILED/UNKNOWN)뿐이다. Office 화면은 이를 다음 시각 상태로만
매핑한다 — 그 이상의 세분화된 상태(THINKING/TESTING 등)는 Claude Code가 제공하지 않으므로
만들지 않는다:

| 실제 STATUS | 화면 표시 |
|---|---|
| WORKING | 작업 중(화면 반짝임 애니메이션) |
| WAITING / REVIEWING | 대기(휴식 포즈) |
| BLOCKED | 경고 링(주의 필요) |
| FAILED | 오류(빨간 펄스) |
| COMPLETED | 정리 중 → 세션이 실제로 목록에서 사라지면 퇴근 애니메이션 |
| UNKNOWN | 회색조("상태 확인 중") |
| (roster 항목, 미연결) | 💤 미출근 — 실제 세션 아님, 항상 이 상태로만 |

## 출퇴근

- **출근**: 세션 ID가 이전에 관측된 적 없으면(페이지 최초 로드의 `hello` 스냅샷 제외) 입장
  애니메이션 1회 재생. 새로고침해도 이미 있던 직원은 재생하지 않는다(세션 ID 기반 추적).
- **퇴근**: `agent-monitor.js`가 **성공적인** `claude agents --json` 호출에서 세션이 더 이상
  보이지 않을 때만 "종료"로 기록 — 일시적 CLI/네트워크 실패로는 상태가 변경되지 않으므로
  가짜 퇴근이 발생하지 않는다. 화면에서는 700ms의 "leaving" 유령 프레임을 거쳐 제거된다.
- `bridge.claudeAvailable`가 `false`(Claude CLI 자체에 연결 불가)가 되면 전 직원을 일괄
  퇴근시키지 않고 배너만 띄운 채 마지막 상태를 유지한다("상태 확인 중").

## 실시간 반영

기존 SSE `/events`(hello/state/log)를 그대로 사용한다. `config/agents.json`은 SSE 스트림에
포함되지 않는 별도의 작은 정적 파일이라 `GET /api/config/agents`를 30초 주기로 폴링해 갱신한다
(재시작 없이 파일 수정이 반영됨). 다른 기존 API(`/api/state`, `/api/tests/run`,
`/api/agents/:id`)는 이번 확장으로 전혀 변경되지 않았다.

## Agent Spawn Architecture

Office의 "+ 직원 출근시키기" 버튼은 `POST /api/agents/spawn`(`agent-spawner.js`)을 통해
**실제** `claude -p --bg` 프로세스를 생성한다. Lifecycle:

```
[Office 폼: 부서 + 업무 입력]
  ↓ POST /api/agents/spawn { department, task }
agent-spawner.js
  — department를 7개 부서 whitelist로 검증
  — 5초 내 같은 부서 중복 요청 거부
  — crypto.randomUUID()로 sessionId 사전 생성
  — spawn('claude', [...고정 플래그...], { cwd: REPO_ROOT, shell: true })
  — task 텍스트는 child.stdin으로만 전달 (argv에는 절대 포함되지 않음)
  ↓ 즉시 { ok, sessionId, name } 응답 ("출근"이 아니라 "요청 접수")
브라우저: state.agents에 그 sessionId가 실제로 나타날 때까지 폴링
  ↓ (agent-monitor.js가 실제 `claude agents --json`에서 관측)
Office: 그 시점에야 "직원이 출근했습니다" + 입장 애니메이션
```

### Session source of truth

`--session-id <uuid>`로 세션 ID를 스폰 시점에 직접 지정한다. Office의 `employeeId`(roster
항목의 `id`)는 표시용일 뿐이며, 실제 Agent identity는 항상 이 Claude Code `sessionId`다 —
스폰 요청과 실제 세션을 이름 추측이나 타이밍 없이 확정적으로 연결하기 위함이다.

### Spawn safety defaults

| 설정 | 값 | 이유 |
|---|---|---|
| `--permission-mode` | `plan` (고정, 변경 불가) | 스폰된 Agent는 조사·계획 수립까지만 하고 자동으로 파일을 수정하거나 명령을 실행하지 않는다. 웹 폼의 자유 텍스트 입력만으로 실제 코드 변경까지 이어지는 것을 막기 위한 1차 구현의 의도적 안전장치 — 실행까지 허용하려면 별도 검토 후 명시적으로 완화해야 한다. |
| `--max-budget-usd` | `2`(고정, 웹 폼에서 조정 불가) | Agent 1회 스폰당 지출 상한. |
| `cwd` | 항상 REPO_ROOT | 요청 바디의 어떤 필드도 이 값에 영향을 줄 수 없다 — path traversal이 구조적으로 불가능. |
| task 전달 | child.stdin (argv 아님) | `claude`는 이 머신에서 `shell:true` 없이는 실행되지 않음(npm .cmd shim, ENOENT 확인됨) — Windows cmd.exe 인용 규칙에는 알려진 우회 사례가 있어, 신뢰할 수 없는 텍스트를 애초에 커맨드라인에 올리지 않는 방식을 택했다. |

### Agent Prompt Template

모든 스폰된 Agent는 `--append-system-prompt`로 공통 원칙(기존 Architecture 존중, 가짜 데이터
금지, 완료 형식 지정) + 부서별 역할 설명을 받는다(`agent-spawner.js`의 `DEPARTMENT_PROMPTS`).

### 종료(Stop) 기능 — 의도적으로 미구현

`claude agents --help`에 특정 background 세션을 안전하게 종료하는 공식 방법이 없고,
background 세션은 `claude agents --json`에 `pid`조차 노출하지 않는다(실제 출력으로 확인 —
`pid`는 interactive 세션에만 있음). 이 상태에서 프로세스를 추측해서 죽이면 엉뚱한 프로세스를
죽이거나 orphan을 남길 위험이 있어 "중단" 버튼을 만들지 않았다. 대신 `--max-budget-usd`로
상한을 걸어 무한 실행 위험을 낮춘다.

### 테스트

- `tools/agent-dashboard/agent-spawner.test.js` — 순수 Node 테스트(프레임워크 없음, 이 도구의
  무의존성 원칙 유지). 실제 `child_process.spawn`을 절대 호출하지 않고 `spawnFn`을 주입해
  argv 구성을 검증한다. 핵심: 어떤 악의적인 task 문자열(`"; rm -rf /`, `` `whoami` ``,
  `$(evil)` 등)을 넣어도 그 문자열이 spawn된 argv 어디에도 나타나지 않고 stdin으로만
  전달됨을 직접 단언한다. 실행: `node agent-spawner.test.js`.
- Office 쪽 spawn 폼(성공/서버 거부 흐름)은 실제 `app.js`를 DOM 스텁 위에서 그대로 실행하는
  기존 회귀 하네스에 통합해 검증했다 — 버튼 클릭만으로 "출근"을 표시하지 않고, `state.agents`에
  해당 sessionId가 실제로 나타난 뒤에만 성공 문구를 보여주는지 확인한다.

## 알려진 한계

- Claude Code CLI는 세션별 role/부서 정보를 제공하지 않는다 — `config/agents.json` 매칭은
  이름 문자열 기반 추정이라, roster 힌트와 우연히 겹치는 이름의 세션이 있으면 의도와 다른
  부서로 매칭될 수 있다(그 경우 수동 드롭다운으로 즉시 정정 가능).
- 세션별 실시간 tool 사용 로그는 opt-in hook(`hooks/dashboard-activity-hook.js`) 없이는
  노출되지 않는다 — 말풍선은 상태 전이 텍스트만 보여준다(기존 제약, 변경 없음).
- Office는 이 저장소(`inProject: true`)로 스코프된 세션만 직원으로 앉힌다. 다른 프로젝트의
  세션은 "다른 프로젝트 세션" 목록에 텍스트로만 표시되고 사무실 캐릭터로는 그리지 않는다
  (서로 다른 저장소의 작업을 뒤섞어 보여주지 않기 위함).
- **`claude -p`가 프롬프트 위치 인자 없이 stdin에서 프롬프트를 읽는지는 이 구현이 전제하는
  부분이지만, 실제 비용이 드는 라이브 스폰으로 아직 검증하지 않았다** — 사용자 확인을 받은 뒤
  실제 첫 스폰에서 함께 검증할 예정. 만약 지원하지 않는다면 `agent-spawner.js`의 인자 구성만
  바뀌면 되고(예: 프롬프트를 위치 인자로 다시 전달하되 여전히 shell 문자열이 아닌 배열로),
  stdin-only 설계 원칙 자체는 유지한다.
- `--permission-mode plan` 고정으로 인해, 지금 스폰되는 Agent는 "조사·계획 수립"까지만 하고
  실제 코드/문서를 수정하지 않는다 — §20/§21(Phase 7 실제 기능 개발과의 연결)을 완성하려면
  이 모드를 완화하는 별도 결정이 필요하다(이번에는 안전을 우선해 보류).
- 스폰 성공/실패 확인은 20초 폴링 타임아웃을 사용한다 — 그 이상 걸리는 정상적인 지연(느린 시스템 등)은
  실제로는 성공했더라도 UI에는 "시간 초과"로 표시될 수 있다(Logs 탭에서 실제 상태 확인 가능).
