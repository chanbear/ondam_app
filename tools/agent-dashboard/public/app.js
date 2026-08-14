(() => {
  'use strict';

  const state = {
    bridge: { claudeAvailable: null, claudeVersion: null, claudeError: null },
    agents: [],
    otherSessions: [],
    git: null,
    tests: {},
    testRuns: [],
    project: null,
    architecture: null,
    logs: [],
  };

  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => Array.from(document.querySelectorAll(sel));

  function fmtTime(ts) {
    if (!ts) return '—';
    return new Date(ts).toLocaleTimeString('ko-KR', { hour12: false });
  }
  function fmtElapsed(startedAt) {
    if (!startedAt) return '—';
    const s = Math.floor((Date.now() - startedAt) / 1000);
    if (s < 60) return `${s}s`;
    if (s < 3600) return `${Math.floor(s / 60)}m ${s % 60}s`;
    return `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m`;
  }
  function escapeHtml(str) {
    return String(str ?? '').replace(/[&<>"']/g, (c) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
    }[c]));
  }
  function shortId(id) {
    return id ? String(id).slice(0, 8) : '—';
  }

  // ---------------- Office: department config (UI-only classification) ----------------
  // Claude Code's CLI never reports an agent "role" (see agent-monitor.js —
  // `role: null` always). Department assignment below is purely a dashboard
  // display preference the user can set per session, stored locally. It is
  // never presented as data Claude Code provided.
  const DEPARTMENTS = [
    { id: 'management', label: 'MANAGEMENT', icon: '🏢', room: 'room-management' },
    { id: 'senior', label: 'SENIOR APP', icon: '📱', room: 'room-senior' },
    { id: 'guardian', label: 'GUARDIAN APP', icon: '👨‍👩‍👧', room: 'room-guardian' },
    { id: 'frontend', label: 'FRONTEND / UI', icon: '🎨', room: 'room-frontend' },
    { id: 'backend', label: 'BACKEND', icon: '🗄️', room: 'room-backend' },
    { id: 'qa', label: 'QA', icon: '🧪', room: 'room-qa' },
    { id: 'docs', label: 'DOCUMENTATION', icon: '📚', room: 'room-docs' },
  ];
  const DEPT_STORAGE_KEY = 'ondam-office-agent-departments';
  function loadDepartments() {
    try { return JSON.parse(localStorage.getItem(DEPT_STORAGE_KEY) || '{}'); } catch (_) { return {}; }
  }
  function saveDepartments(map) {
    try { localStorage.setItem(DEPT_STORAGE_KEY, JSON.stringify(map)); } catch (_) { /* ignore */ }
  }
  const agentDepartments = loadDepartments();

  // ---------------- Office: agent roster registry (config/agents.json) ----------------
  // A user-editable *display* registry served read-only from
  // GET /api/config/agents (config-reader.js — never fabricates or caches a
  // fallback roster). Used only to (a) suggest a department/role label for a
  // REAL connected session by matching its real `kind`/`name`, and (b) show
  // how many of the declared roster slots for a department are currently
  // unfilled. A roster entry with no matching real session is NEVER rendered
  // as a working employee — only as an empty/offline slot.
  let agentRoster = [];
  // True only once the SSE `hello` snapshot has actually populated
  // state.agents from the server. Guards against fetchAgentRoster()'s own
  // render (which can resolve before `hello` does) prematurely consuming
  // buildOfficeEmployeeList's "first render" flag against an empty/stub
  // state.agents — which would make the real first `hello` look like a
  // fresh arrival and incorrectly replay the entrance animation.
  let hasLiveSnapshot = false;
  async function fetchAgentRoster() {
    try {
      const res = await fetch('/api/config/agents');
      const body = await res.json();
      agentRoster = body.ok ? body.roster : [];
    } catch (_) {
      agentRoster = [];
    }
    if (hasLiveSnapshot) renderOffice();
  }

  function matchRosterEntry(agent) {
    for (const entry of agentRoster) {
      const m = entry.match || {};
      if (m.kind && agent.rawKind === m.kind) return entry;
      if (Array.isArray(m.nameContains) && agent.name) {
        const lower = agent.name.toLowerCase();
        if (m.nameContains.some((s) => lower.includes(String(s).toLowerCase()))) return entry;
      }
    }
    return null;
  }

  // Manual per-session override (the modal's department dropdown) always
  // wins over the roster's automatic name/kind matching.
  function computeAssignment(agent) {
    const manual = agentDepartments[agent.sessionId];
    if (manual && DEPARTMENTS.some((d) => d.id === manual)) {
      return { dept: manual, entryId: null, role: null, displayLabel: null, source: 'manual' };
    }
    const entry = matchRosterEntry(agent);
    if (entry) return { dept: entry.department, entryId: entry.id, role: entry.role, displayLabel: entry.displayName, source: 'roster' };
    return { dept: 'open', entryId: null, role: null, displayLabel: null, source: 'none' };
  }

  const STATUS_VISUAL = {
    WORKING: { cls: 'status-working', icon: '💻', label: '작업 중' },
    WAITING: { cls: 'status-idle', icon: '☕', label: '대기 중(쉬는 중)' },
    REVIEWING: { cls: 'status-idle', icon: '📖', label: '검토 중' },
    BLOCKED: { cls: 'status-blocked', icon: '⚠️', label: '막힘 — 확인 필요' },
    COMPLETED: { cls: 'status-done', icon: '✅', label: '완료 — 정리 중' },
    FAILED: { cls: 'status-error', icon: '🔴', label: '오류' },
    UNKNOWN: { cls: 'status-unknown', icon: '❔', label: '상태 확인 중' },
  };
  function statusVisual(status) { return STATUS_VISUAL[status] || STATUS_VISUAL.UNKNOWN; }

  const EMP_PALETTE = ['#6ec6ff', '#ffb86e', '#b58cff', '#7ee0a8', '#ff9fb2', '#ffd76e'];
  function empColor(id) {
    let h = 0;
    const s = String(id || '');
    for (let i = 0; i < s.length; i += 1) h = (h * 31 + s.charCodeAt(i)) >>> 0;
    return EMP_PALETTE[h % EMP_PALETTE.length];
  }

  // Turns the REAL activity strings agent-monitor.js already records (state
  // transitions, or per-tool hook events) into a short Korean caption. Never
  // invents a task description that isn't backed by one of these strings.
  function humanizeActivity(entry) {
    if (!entry) return null;
    const text = entry.text || '';
    if (entry.source === 'hook') return text; // real per-tool activity from the opt-in hook
    if (/^Session detected/.test(text)) return '출근 확인됨';
    if (/^Session ended/.test(text)) return '퇴근 처리됨';
    const m = text.match(/^Status changed: (\w+) → (\w+)/);
    if (m) return `상태 전환: ${m[1]} → ${m[2]}`;
    return text;
  }

  // Prefers the REAL Korean text docs-reader.js already parsed straight out of
  // implementation-plan.md (`p.headline`) over the English placeholder label
  // it falls back to when no matching "### Phase N" header was found. Only
  // strips markdown bold markers and the trailing "(vN: ...)" version tag —
  // never rewrites the actual sentence.
  function phaseDisplayLabel(p) {
    if (p.headline) {
      return p.headline.replace(/\*\*/g, '').replace(/\s*\(v\d+[^)]*\)\s*$/, '').trim();
    }
    return p.label;
  }

  function aggregateCmdStatus(cmd) {
    const runs = state.testRuns || [];
    if (runs.some((r) => r.cmd === cmd && r.status === 'RUNNING')) return 'RUNNING';
    const entries = ['senior', 'guardian']
      .map((t) => (state.tests || {})[t] && state.tests[t][cmd])
      .filter(Boolean);
    if (entries.length === 0) return null;
    if (entries.some((e) => e.status === 'FAIL')) return 'FAIL';
    return 'PASS';
  }

  // ---------------- Navigation ----------------
  $$('.nav-item').forEach((btn) => {
    btn.addEventListener('click', () => {
      $$('.nav-item').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      const view = btn.dataset.view;
      $$('.view').forEach((v) => v.classList.remove('active'));
      $(`#view-${view}`).classList.add('active');
    });
  });

  // ---------------- SSE ----------------
  let es = null;
  let reconnectDelay = 1000;

  function setLiveIndicator(status) {
    const el = $('#live-indicator');
    el.classList.remove('connected', 'reconnecting', 'offline');
    if (status === 'connected') {
      el.textContent = '● Connected';
      el.classList.add('connected');
    } else if (status === 'reconnecting') {
      el.textContent = '○ Reconnecting…';
      el.classList.add('reconnecting');
    } else {
      el.textContent = '● OFFLINE';
      el.classList.add('offline');
    }
  }

  function connect() {
    setLiveIndicator('reconnecting');
    es = new EventSource('/events');

    es.addEventListener('hello', (ev) => {
      const snapshot = JSON.parse(ev.data);
      Object.assign(state, snapshot);
      hasLiveSnapshot = true;
      reconnectDelay = 1000;
      setLiveIndicator('connected');
      renderAll();
    });

    es.addEventListener('state', (ev) => {
      const { key, value } = JSON.parse(ev.data);
      state[key] = value;
      renderAll();
    });

    es.addEventListener('log', (ev) => {
      const entry = JSON.parse(ev.data);
      state.logs.push(entry);
      if (state.logs.length > 300) state.logs.shift();
      renderLogs();
    });

    es.onopen = () => setLiveIndicator('connected');

    es.onerror = () => {
      setLiveIndicator('reconnecting');
      es.close();
      setTimeout(connect, reconnectDelay);
      reconnectDelay = Math.min(reconnectDelay * 1.6, 15000);
      // If the browser can't even reach the bridge process, treat it as OFFLINE.
      fetch('/api/state').catch(() => setLiveIndicator('offline'));
    };
  }

  // ---------------- Renderers ----------------
  function renderAll() {
    renderTopbar();
    renderOffice();
    renderOverview();
    renderAgents();
    renderTasks();
    renderGit();
    renderTests();
    renderArchitecture();
    renderLogs();
  }

  function renderTopbar() {
    const phase = state.project && state.project.currentPhase;
    $('#chip-phase').textContent = phase ? `PHASE ${phase.number}` : 'PHASE —';

    const count = state.agents.length;
    $('#chip-agents').textContent = `${count} Agent${count === 1 ? '' : 's'} Running`;

    const git = state.git;
    if (!git) $('#chip-git').textContent = 'Git: —';
    else if (!git.ok) $('#chip-git').textContent = 'Git: Unavailable';
    else $('#chip-git').textContent = git.clean ? 'Working Tree Clean' : `${git.modified} modified, ${git.untracked} untracked`;

    const testEntries = Object.values(state.tests || {}).flatMap((t) => Object.values(t));
    if (testEntries.length === 0) $('#chip-tests').textContent = 'Tests: Not run';
    else {
      const anyFail = testEntries.some((t) => t.status === 'FAIL');
      $('#chip-tests').textContent = anyFail ? 'Tests: Failing' : 'Tests: Passing';
    }
    const buildStatus = aggregateCmdStatus('build');
    $('#chip-build').textContent = buildStatus ? `Build: ${buildStatus}` : 'Build: —';

    $('#footer-branch').textContent = git && git.ok ? git.branch : 'Unavailable';
    const claudeText = state.bridge.claudeAvailable === null
      ? '— checking —'
      : state.bridge.claudeAvailable
        ? `● Connected (${state.bridge.claudeVersion || 'unknown version'})`
        : '○ Offline';
    $('#footer-claude').textContent = claudeText;
  }

  function phaseMarkClass(status) {
    if (status === 'DONE') return 'done';
    if (status === 'READY') return 'current';
    return 'planned';
  }
  function phaseMarkSymbol(status) {
    if (status === 'DONE') return '✓';
    if (status === 'READY') return '●';
    return '○';
  }

  function renderPhaseList(target) {
    const el = $(target);
    if (!state.project || !state.project.phases) {
      el.innerHTML = '<li class="empty-note">Project docs not found — phase list unavailable.</li>';
      return;
    }
    el.innerHTML = state.project.phases.map((p) => `
      <li class="phase-item">
        <span class="phase-num">Phase ${p.number}</span>
        <span class="phase-mark ${phaseMarkClass(p.status)}">${phaseMarkSymbol(p.status)}</span>
        <span class="phase-label">${escapeHtml(p.label)}</span>
        ${p.inferred ? '<span class="phase-inferred">(inferred)</span>' : ''}
      </li>
    `).join('');
  }

  function renderOverview() {
    $('#overview-current-phase').textContent = state.project && state.project.currentPhase
      ? `Current phase: Phase ${state.project.currentPhase.number} — ${state.project.currentPhase.label}`
      : 'Current phase: Unavailable';
    renderPhaseList('#phase-list');

    const git = state.git;
    const testEntries = Object.entries(state.tests || {});
    $('#summary-grid').innerHTML = `
      <div class="summary-tile"><div class="summary-tile-label">Agents (this project)</div><div class="summary-tile-value">${state.agents.length}</div></div>
      <div class="summary-tile"><div class="summary-tile-label">Other sessions</div><div class="summary-tile-value">${state.otherSessions.length}</div></div>
      <div class="summary-tile"><div class="summary-tile-label">Git branch</div><div class="summary-tile-value">${git && git.ok ? escapeHtml(git.branch) : 'Unavailable'}</div></div>
      <div class="summary-tile"><div class="summary-tile-label">Working tree</div><div class="summary-tile-value">${git && git.ok ? (git.clean ? 'Clean' : `${git.modified}M ${git.staged}S ${git.untracked}U`) : '—'}</div></div>
      <div class="summary-tile"><div class="summary-tile-label">Last test run</div><div class="summary-tile-value">${testEntries.length ? 'See Tests tab' : 'None'}</div></div>
      <div class="summary-tile"><div class="summary-tile-label">Claude Code</div><div class="summary-tile-value">${state.bridge.claudeAvailable ? 'Connected' : 'Offline'}</div></div>
    `;

    const allActivity = [];
    for (const a of state.agents.concat(state.otherSessions)) {
      for (const act of a.recentActivity || []) {
        allActivity.push({ ts: act.ts, source: a.name || shortId(a.sessionId), text: act.text });
      }
    }
    allActivity.sort((a, b) => b.ts - a.ts);
    const top = allActivity.slice(0, 20);
    $('#overview-activity').innerHTML = top.length
      ? top.map((a) => `
        <div class="activity-row">
          <span class="activity-ts">${fmtTime(a.ts)}</span>
          <span class="activity-src">${escapeHtml(a.source)}</span>
          <span class="activity-text">${escapeHtml(a.text)}</span>
        </div>
      `).join('')
      : '<div class="empty-note">No real activity observed yet — this feed only shows genuine state changes, never simulated events.</div>';
  }

  function statusBadge(status) {
    return `<span class="status-badge status-${status}">${status}</span>`;
  }

  function agentCardHtml(a, dim) {
    const label = a.name ? escapeHtml(a.name) : `Session ${shortId(a.sessionId)}`;
    return `
      <div class="agent-card" data-session-id="${escapeHtml(a.sessionId)}">
        ${statusBadge(a.status)}
        <div class="agent-card-name">Claude Code Agent — ${label}</div>
        <div class="agent-card-task">${a.currentTask ? escapeHtml(a.currentTask) : 'No session label set'}</div>
        <div class="agent-card-meta">
          <span>Session: ${shortId(a.sessionId)}</span>
          <span>Started: ${fmtTime(a.startedAt)} (${fmtElapsed(a.startedAt)} ago)</span>
          <span>Branch: ${a.branch ? escapeHtml(a.branch) : 'Unavailable'}</span>
          <span>Progress: Progress unavailable</span>
        </div>
      </div>
    `;
  }

  function renderAgents() {
    $('#agent-grid').innerHTML = state.agents.map((a) => agentCardHtml(a, false)).join('');
    $('#agents-empty-note').style.display = state.agents.length === 0 ? 'block' : 'none';
    $('#other-agent-grid').innerHTML = state.otherSessions.map((a) => agentCardHtml(a, true)).join('')
      || '<div class="empty-note">None detected.</div>';

    $$('.agent-card').forEach((card) => {
      card.addEventListener('click', () => openAgentModal(card.dataset.sessionId));
    });
  }

  function findAgent(sessionId) {
    return state.agents.find((a) => a.sessionId === sessionId) || state.otherSessions.find((a) => a.sessionId === sessionId);
  }

  function openAgentModal(sessionId) {
    const a = findAgent(sessionId);
    if (!a) return;
    $('#modal-title').textContent = a.name || `Session ${shortId(sessionId)}`;
    const activity = (a.recentActivity || []).slice().reverse();
    $('#modal-body').innerHTML = `
      <div class="kv-row"><span class="kv-label">Status</span><span class="kv-value">${statusBadge(a.status)}</span></div>
      <div class="kv-row"><span class="kv-label">Session ID</span><span class="kv-value">${escapeHtml(a.sessionId)}</span></div>
      <div class="kv-row"><span class="kv-label">Current task (session label)</span><span class="kv-value">${a.currentTask ? escapeHtml(a.currentTask) : 'Unavailable'}</span></div>
      <div class="kv-row"><span class="kv-label">Started At</span><span class="kv-value">${fmtTime(a.startedAt)}</span></div>
      <div class="kv-row"><span class="kv-label">Elapsed</span><span class="kv-value">${fmtElapsed(a.startedAt)}</span></div>
      <div class="kv-row"><span class="kv-label">Branch</span><span class="kv-value">${a.branch ? escapeHtml(a.branch) + ' (from git, not Claude Code)' : 'Unavailable'}</span></div>
      <div class="kv-row"><span class="kv-label">Working Directory</span><span class="kv-value">${escapeHtml(a.cwd || 'Unknown')}</span></div>
      <div class="kv-row"><span class="kv-label">PID</span><span class="kv-value">${a.pid || 'Not exposed (background session)'}</span></div>
      <div class="kv-row"><span class="kv-label">Tools used</span><span class="kv-value">Unknown — not exposed unless the optional hook is enabled</span></div>
      <div class="panel-title" style="margin-top:16px;">Recent Activities</div>
      <div class="activity-feed">
        ${activity.length ? activity.map((act) => `
          <div class="activity-row">
            <span class="activity-ts">${fmtTime(act.ts)}</span>
            <span class="activity-src">${act.source}</span>
            <span class="activity-text">${escapeHtml(act.text)}</span>
          </div>`).join('') : '<div class="empty-note">No observed activity yet.</div>'}
      </div>
      ${a.inProject ? `
        <div class="panel-title" style="margin-top:16px;">부서 배정 (Dashboard 표시용 분류)</div>
        <select class="office-dept-select" id="modal-dept-select">
          <option value="">미배정 (오픈 오피스)</option>
          ${DEPARTMENTS.map((d) => `<option value="${d.id}" ${agentDepartments[a.sessionId] === d.id ? 'selected' : ''}>${d.icon} ${d.label}</option>`).join('')}
        </select>
        <div class="office-dept-note">
          ※ Claude Code가 제공하는 실제 role 정보가 아니라, 이 Dashboard 화면에서만 쓰이는 분류입니다.
          ${!agentDepartments[a.sessionId] && matchRosterEntry(a) ? ` config/agents.json 매칭 결과: "${escapeHtml(matchRosterEntry(a).role || '')}"(자동 추정, 위 드롭다운으로 언제든 덮어쓸 수 있음)` : ''}
        </div>
      ` : ''}
      <div class="panel-title" style="margin-top:16px;">Raw Agent Data</div>
      <details class="raw-agent-data"><summary>claude agents --json 원본 필드 보기</summary><pre>${escapeHtml(JSON.stringify(a, null, 2))}</pre></details>
      <div class="stop-status-line" id="modal-stop-status"></div>
      <div class="modal-btn-row">
        <button class="btn" id="modal-view-log">로그 보기</button>
        <button class="btn" id="modal-view-git">Git 변경 보기</button>
        ${a.inProject && a.rawKind === 'background' ? '<button class="btn btn-danger" id="modal-stop-agent">퇴근시키기</button>' : ''}
      </div>
    `;
    $('#modal-backdrop').classList.add('open');

    const deptSelect = $('#modal-dept-select');
    if (deptSelect) {
      deptSelect.addEventListener('change', () => {
        if (deptSelect.value) agentDepartments[a.sessionId] = deptSelect.value;
        else delete agentDepartments[a.sessionId];
        saveDepartments(agentDepartments);
        renderOffice();
      });
    }
    const viewLogBtn = $('#modal-view-log');
    if (viewLogBtn) {
      viewLogBtn.addEventListener('click', () => {
        $('#modal-backdrop').classList.remove('open');
        $$('.nav-item').forEach((b) => b.classList.remove('active'));
        $('.nav-item[data-view="logs"]').classList.add('active');
        $$('.view').forEach((v) => v.classList.remove('active'));
        $('#view-logs').classList.add('active');
        $('#logs-search').value = shortId(a.sessionId);
        renderLogs();
      });
    }
    const viewGitBtn = $('#modal-view-git');
    if (viewGitBtn) {
      viewGitBtn.addEventListener('click', () => {
        $('#modal-backdrop').classList.remove('open');
        $$('.nav-item').forEach((b) => b.classList.remove('active'));
        $('.nav-item[data-view="git"]').classList.add('active');
        $$('.view').forEach((v) => v.classList.remove('active'));
        $('#view-git').classList.add('active');
      });
    }
    const stopBtn = $('#modal-stop-agent');
    if (stopBtn) {
      stopBtn.addEventListener('click', async () => {
        const stopStatus = $('#modal-stop-status');
        stopBtn.disabled = true;
        stopStatus.textContent = '실제 claude stop 호출 중...';
        stopStatus.className = 'stop-status-line pending';
        try {
          const res = await fetch(`/api/agents/${encodeURIComponent(a.sessionId)}/stop`, { method: 'POST' });
          const body = await res.json();
          if (!body.ok) {
            stopStatus.textContent = `퇴근 실패: ${body.error}`;
            stopStatus.className = 'stop-status-line error';
            stopBtn.disabled = false;
            return;
          }
          // No optimistic status change — the real state comes from the
          // next agent-monitor.js poll (SSE push), same principle as spawn
          // confirmation. This just reports that the CLI call itself
          // succeeded; the desk animation plays when the session actually
          // disappears/shows "stopped".
          stopStatus.textContent = 'claude stop 호출 성공 — 실제 세션 상태 갱신을 기다리는 중 (곧 퇴근 처리됩니다).';
          stopStatus.className = 'stop-status-line ok';
        } catch (err) {
          stopStatus.textContent = `퇴근 요청 실패: ${err.message}`;
          stopStatus.className = 'stop-status-line error';
          stopBtn.disabled = false;
        }
      });
    }
  }
  $('#modal-close').addEventListener('click', () => $('#modal-backdrop').classList.remove('open'));
  $('#modal-backdrop').addEventListener('click', (e) => {
    if (e.target.id === 'modal-backdrop') $('#modal-backdrop').classList.remove('open');
  });

  // ---------------- Office: real Agent spawn ----------------
  // POSTs to /api/agents/spawn (agent-spawner.js) — a REAL `claude -p --bg`
  // process. This UI never marks anyone "출근" on click alone: it waits for
  // the spawned session to actually appear in state.agents (i.e. for
  // agent-monitor.js to have observed it via a real `claude agents --json`
  // poll) before saying so, and reports a real timeout/error otherwise.
  function openSpawnModal() {
    $('#modal-title').textContent = '+ 직원 출근시키기';
    $('#modal-body').innerHTML = `
      <div class="spawn-form">
        <div>
          <label for="spawn-dept">부서</label>
          <select id="spawn-dept">
            ${DEPARTMENTS.map((d) => `<option value="${d.id}">${d.icon} ${d.label}</option>`).join('')}
          </select>
          <div class="spawn-role-hint" id="spawn-role-hint"></div>
        </div>
        <div>
          <label for="spawn-task">업무</label>
          <textarea id="spawn-task" maxlength="4000" placeholder="예: Phase 7 SMS 기능 구현을 조사하고 현재 ONDAM Architecture에 맞는 구현 계획을 작성하라"></textarea>
        </div>
        <div class="spawn-status-line" id="spawn-status"></div>
        <div class="modal-btn-row">
          <button class="btn office-spawn-btn" id="spawn-submit">출근시키기</button>
        </div>
        <div class="spawn-safety-note">
          실제 Claude Code 프로세스를 생성합니다(<code>claude -p --bg</code>). 안전을 위해 permission-mode는 "plan"(조사·계획 수립만, 자동 코드 수정 없음)으로 고정되어 있고 Agent당 예산 상한이 걸려 있습니다. 세션이 실제로 감지된 경우에만 "출근"으로 표시됩니다 — 버튼 클릭 자체가 출근을 의미하지 않습니다.
        </div>
      </div>
    `;
    $('#modal-backdrop').classList.add('open');

    const deptSelect = $('#spawn-dept');
    const roleHint = $('#spawn-role-hint');
    const OCCUPIED = new Set(['WORKING', 'WAITING', 'REVIEWING', 'BLOCKED']);
    // Client-side hint only — the real, authoritative same-department-busy
    // rejection happens server-side (agent-spawner.js's isDepartmentBusy()),
    // since state.agents here can be a poll cycle stale. This just saves a
    // round trip for the obvious case.
    function departmentBusyAgent(dept) {
      return (state.agents || []).find((a) => OCCUPIED.has(a.status) && matchRosterEntry(a) && matchRosterEntry(a).department === dept);
    }
    function updateRoleHint() {
      const entry = agentRoster.find((r) => r.department === deptSelect.value);
      const busy = departmentBusyAgent(deptSelect.value);
      if (busy) {
        roleHint.textContent = `⚠ 이 부서는 이미 "${busy.name || shortId(busy.sessionId)}"가 근무 중입니다(${busy.status}). 완료/퇴근 후 다시 시도하세요.`;
      } else {
        roleHint.textContent = entry && entry.role
          ? `config/agents.json 기본 역할: ${entry.role}`
          : '이 부서에 registry 항목이 없습니다 — 연결되면 오픈 오피스로 표시됩니다.';
      }
    }
    deptSelect.addEventListener('change', updateRoleHint);
    updateRoleHint();

    const statusEl = $('#spawn-status');
    const submitBtn = $('#spawn-submit');
    submitBtn.addEventListener('click', async () => {
      const department = deptSelect.value;
      const task = $('#spawn-task').value.trim();
      if (!task) {
        statusEl.textContent = '업무 내용을 입력하세요.';
        statusEl.className = 'spawn-status-line error';
        return;
      }
      submitBtn.disabled = true;
      statusEl.textContent = '요청 전송 중...';
      statusEl.className = 'spawn-status-line pending';
      try {
        const res = await fetch('/api/agents/spawn', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ department, task }),
        });
        const body = await res.json();
        if (!body.ok) {
          statusEl.textContent = `직원을 출근시키지 못했습니다: ${body.error}`;
          statusEl.className = 'spawn-status-line error';
          submitBtn.disabled = false;
          return;
        }
        statusEl.textContent = '요청 완료 — 실제 세션 확인 중...';
        statusEl.className = 'spawn-status-line pending';
        waitForSpawnConfirmation(body.sessionId, statusEl, submitBtn);
      } catch (err) {
        statusEl.textContent = `요청 실패: ${err.message}`;
        statusEl.className = 'spawn-status-line error';
        submitBtn.disabled = false;
      }
    });
  }

  function waitForSpawnConfirmation(shortId, statusEl, submitBtn) {
    const startedAt = Date.now();
    const TIMEOUT_MS = 20000;
    const check = () => {
      // /api/agents/spawn now returns the CLI's own short id (parsed from
      // `--bg`'s "backgrounded · <id> · <name>" stdout line), not a
      // pre-generated full UUID — match on `a.id`, which agent-monitor.js's
      // _normalize() sets to that same short id (`session.id || sessionId`).
      const found = (state.agents || []).some((a) => a.id === shortId);
      if (found) {
        statusEl.textContent = '직원이 출근했습니다!';
        statusEl.className = 'spawn-status-line ok';
        submitBtn.disabled = false;
        return;
      }
      if (Date.now() - startedAt > TIMEOUT_MS) {
        statusEl.textContent = '출근 확인 시간 초과 — Logs 탭에서 spawn 로그를 확인하세요 (아직 등록 중일 수 있습니다).';
        statusEl.className = 'spawn-status-line error';
        submitBtn.disabled = false;
        return;
      }
      setTimeout(check, 1000);
    };
    check();
  }

  const spawnOpenBtn = $('#office-spawn-open');
  if (spawnOpenBtn) spawnOpenBtn.addEventListener('click', openSpawnModal);

  function renderTasks() {
    const columns = { BACKLOG: [], 'IN PROGRESS': [], REVIEW: [], DONE: [], BLOCKED: [] };
    for (const a of state.agents) {
      const label = a.name || `Session ${shortId(a.sessionId)}`;
      if (a.status === 'WORKING') columns['IN PROGRESS'].push({ label, badge: null });
      else if (a.status === 'BLOCKED') columns.BLOCKED.push({ label, badge: null });
      else if (a.status === 'COMPLETED') columns.DONE.push({ label, badge: null });
      else if (a.status === 'FAILED') columns.DONE.push({ label, badge: 'FAILED' });
    }
    const notes = {
      BACKLOG: 'No live data for this column — Claude Code does not expose a task queue.',
      REVIEW: 'No live data for this column — Claude Code does not expose a task queue.',
    };
    $('#task-board').innerHTML = Object.entries(columns).map(([col, items]) => `
      <div class="board-col">
        <div class="board-col-title">${col}</div>
        ${items.map((i) => `
          <div class="board-card">
            <div class="board-card-name">${escapeHtml(i.label)}${i.badge ? ` <span class="status-badge status-FAILED">${i.badge}</span>` : ''}</div>
          </div>
        `).join('')}
        ${items.length === 0 ? `<div class="board-empty">${notes[col] || 'Empty'}</div>` : ''}
      </div>
    `).join('');
    renderPhaseList('#plan-phase-list');
  }

  function renderGit() {
    const git = state.git;
    if (!git) {
      $('#git-summary').innerHTML = '<div class="empty-note">Loading…</div>';
      $('#git-tree').innerHTML = '';
      $('#commit-list').innerHTML = '';
      return;
    }
    if (!git.ok) {
      $('#git-summary').innerHTML = `<div class="empty-note">Unavailable: ${escapeHtml(git.error)}</div>`;
      $('#git-tree').innerHTML = '';
      $('#commit-list').innerHTML = '';
      return;
    }
    $('#git-summary').innerHTML = `
      <div class="kv-row"><span class="kv-label">Branch</span><span class="kv-value">${escapeHtml(git.branch)}</span></div>
      <div class="kv-row"><span class="kv-label">Commit</span><span class="kv-value">${escapeHtml(git.commitHash)}</span></div>
      <div class="kv-row"><span class="kv-label">Last commit</span><span class="kv-value">${escapeHtml(git.commitLine)}</span></div>
    `;
    $('#git-tree').innerHTML = `
      <div class="kv-row"><span class="kv-label">Status</span><span class="kv-value">${git.clean ? 'CLEAN' : 'DIRTY'}</span></div>
      <div class="kv-row"><span class="kv-label">Staged</span><span class="kv-value">${git.staged}</span></div>
      <div class="kv-row"><span class="kv-label">Modified</span><span class="kv-value">${git.modified}</span></div>
      <div class="kv-row"><span class="kv-label">Untracked</span><span class="kv-value">${git.untracked}</span></div>
    `;
    $('#commit-list').innerHTML = (git.recentCommits || []).map((c) => `
      <li class="commit-item">
        <span class="commit-hash">${escapeHtml(c.hash)}</span>
        <span class="commit-subject">${escapeHtml(c.subject)}</span>
        <span class="commit-meta">${escapeHtml(c.author)} · ${escapeHtml(c.when)}</span>
      </li>
    `).join('') || '<li class="empty-note">No commits found.</li>';
  }

  function renderTests() {
    for (const target of ['senior', 'guardian']) {
      const t = (state.tests || {})[target] || {};
      const parts = ['analyze', 'test', 'build'].map((cmd) => {
        const r = t[cmd];
        if (!r) return `${cmd}: not run`;
        return `${cmd}: ${r.status}`;
      });
      $(`#status-${target}`).textContent = parts.join('  ·  ');
    }

    $('#test-runs').innerHTML = (state.testRuns || []).length
      ? state.testRuns.map((r) => `
        <div class="test-run">
          <div class="test-run-head">
            <span>${r.target} — ${r.cmd}</span>
            <span class="run-${r.status}">${r.status}${r.exitCode !== null ? ` (exit ${r.exitCode})` : ''}</span>
          </div>
          <div class="test-run-tail">${escapeHtml((r.tail || []).map((t) => t.text).join(''))}</div>
        </div>
      `).join('')
      : '<div class="empty-note">No test runs yet.</div>';
  }

  $$('.btn[data-target]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      btn.disabled = true;
      try {
        const res = await fetch('/api/tests/run', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ target: btn.dataset.target, cmd: btn.dataset.cmd }),
        });
        const body = await res.json();
        if (!body.ok) {
          // eslint-disable-next-line no-alert
          alert(`Could not start run: ${body.error}`);
        }
      } catch (err) {
        // eslint-disable-next-line no-alert
        alert(`Request failed: ${err.message}`);
      } finally {
        setTimeout(() => { btn.disabled = false; }, 1500);
      }
    });
  });

  function renderArchitecture() {
    const arch = state.architecture;
    if (!arch) {
      $('#arch-apps').innerHTML = '<div class="empty-note">Unavailable.</div>';
      $('#arch-packages').innerHTML = '';
      return;
    }
    $('#arch-apps').innerHTML = `<div class="tag-row">${arch.apps.map((a) => `<span class="tag ${a.exists ? '' : 'missing'}">apps/${a.name}</span>`).join('')}</div>`;
    $('#arch-packages').innerHTML = arch.packages.length
      ? `<div class="tag-row">${arch.packages.map((p) => `<span class="tag">packages/${escapeHtml(p)}</span>`).join('')}</div>`
      : '<div class="empty-note">No packages/ directory found.</div>';
  }

  let activeFilter = 'all';
  $$('.filter-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      $$('.filter-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      activeFilter = btn.dataset.filter;
      renderLogs();
    });
  });
  $('#logs-search').addEventListener('input', renderLogs);

  function renderLogs() {
    const q = $('#logs-search').value.trim().toLowerCase();
    const rows = state.logs
      .filter((l) => activeFilter === 'all' || l.source === activeFilter || (activeFilter === 'error' && l.level === 'error'))
      .filter((l) => !q || l.message.toLowerCase().includes(q))
      .slice(-200)
      .reverse();
    $('#log-list').innerHTML = rows.length
      ? rows.map((l) => `
        <div class="log-row level-${l.level}">
          <span class="log-ts">${fmtTime(l.ts)}</span>
          <span class="log-src">${escapeHtml(l.source)}</span>
          <span class="log-msg">${escapeHtml(l.message)}</span>
        </div>
      `).join('')
      : '<div class="empty-note">No log entries.</div>';
  }

  // ================= Office: employee arrival/departure tracking =================
  // These three collections are the ONLY state that decides animation, and
  // they are all driven off state.agents (real `claude agents --json` data,
  // scoped to this project by agent-monitor.js). Nothing here is a timer-based
  // fake status change — a desk only animates because a real session appeared
  // in or dropped out of state.agents.
  let officeFirstRender = true;
  const officeCache = new Map(); // sessionId -> { agent, dept }
  const leavingIds = new Set();
  const knownEmployeeIds = new Set();

  function buildOfficeEmployeeList() {
    const currentAgents = state.agents || [];
    const currentIds = new Set(currentAgents.map((a) => a.sessionId));

    for (const a of currentAgents) {
      officeCache.set(a.sessionId, { agent: a, assignment: computeAssignment(a) });
      leavingIds.delete(a.sessionId); // still here (or came back) — cancel any pending departure
    }

    // A session in our cache that's no longer in the live list has genuinely
    // ended or gone out of scope (agent-monitor.js only updates state.agents
    // on a SUCCESSFUL `claude agents --json` call — a transient CLI/network
    // failure leaves state.agents untouched, so this never fires on a blip).
    for (const id of officeCache.keys()) {
      if (!currentIds.has(id) && !leavingIds.has(id)) {
        leavingIds.add(id);
        setTimeout(() => {
          officeCache.delete(id);
          leavingIds.delete(id);
          knownEmployeeIds.delete(id);
          renderOffice();
        }, 700);
      }
    }

    const list = [];
    for (const [id, entry] of officeCache) {
      const isNew = officeFirstRender ? false : !knownEmployeeIds.has(id);
      list.push({
        id,
        agent: entry.agent,
        assignment: entry.assignment,
        anim: leavingIds.has(id) ? 'leaving' : (isNew ? 'entering' : 'normal'),
      });
    }
    for (const id of currentIds) knownEmployeeIds.add(id);
    officeFirstRender = false;
    return list;
  }

  // ---- Pixel-art employee sprite (canvas-based) -------------------------
  // Replaces the old div-stack (.e-head/.e-body/.e-legs) sprite with a
  // hand-drawn pixel character on a 34x44 <canvas>, redrawn every animation
  // frame from the canvas's own data-status/data-shirt attributes (set in
  // deskSlotHtml()/emptySlotHtml()). Canvases are re-queried every frame —
  // never cached by id/reference — because renderOffice() periodically
  // replaces #office-floor's innerHTML wholesale (SSE updates + the 5s
  // recompute interval); any cached canvas/context would go stale the
  // instant that happens.
  const PIXEL_INK = '#14151c';
  const PIXEL_SKIN = '#f2c396';
  const PIXEL_CAP = '#232733';
  const PIXEL_PANTS = '#2f333d';

  function shadeColor(hex, percent) {
    const num = parseInt(String(hex).replace('#', ''), 16) || 0;
    const clamp = (v) => Math.max(0, Math.min(255, v));
    const r = clamp(((num >> 16) & 0xff) + Math.round(255 * percent));
    const g = clamp(((num >> 8) & 0xff) + Math.round(255 * percent));
    const b = clamp((num & 0xff) + Math.round(255 * percent));
    return `rgb(${r}, ${g}, ${b})`;
  }

  // Filled rect with a crisp 1px inset outline — the "game sprite" look
  // every block of the character uses.
  function pixelRect(ctx, x, y, w, h, fill) {
    ctx.fillStyle = fill;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = PIXEL_INK;
    ctx.lineWidth = 1;
    ctx.strokeRect(x + 0.5, y + 0.5, w - 1, h - 1);
  }

  // Draws one RPG-style pixel character into a 34x44 canvas: legs -> body
  // (shirt, 3-tone shaded) -> arms -> head+cap, outlined throughout. `t` is
  // an ever-increasing timestamp (the rAF callback's DOMHighResTimeStamp)
  // used only to animate WORKING's typing sway — it is not real activity
  // data, just an animation clock.
  function drawPixelEmployee(ctx, shirt, status, t) {
    ctx.clearRect(0, 0, 34, 44);

    const resting = status === 'OFFLINE' || status === 'UNKNOWN';
    const typing = status === 'WORKING';
    const armSwing = typing ? Math.sin(t / 140) * 2 : 0;

    // legs
    pixelRect(ctx, 11, 29, 5, 10, PIXEL_PANTS);
    pixelRect(ctx, 18, 29, 5, 10, PIXEL_PANTS);

    // body (shirt), 3-tone shading: base fill + lighter collar strip +
    // darker waist strip, all inside one outlined silhouette.
    pixelRect(ctx, 8, 16, 18, 13, shirt);
    ctx.fillStyle = shadeColor(shirt, 0.18);
    ctx.fillRect(9, 17, 16, 3);
    ctx.fillStyle = shadeColor(shirt, -0.22);
    ctx.fillRect(9, 24, 16, 4);
    ctx.strokeStyle = PIXEL_INK;
    ctx.lineWidth = 1;
    ctx.strokeRect(8.5, 16.5, 17, 12);

    // arms — sway like typing while WORKING, still otherwise
    const sleeve = shadeColor(shirt, -0.08);
    pixelRect(ctx, 3, 18 + armSwing, 5, 8, sleeve);
    pixelRect(ctx, 3, 26 + armSwing, 5, 4, PIXEL_SKIN);
    pixelRect(ctx, 26, 18 - armSwing, 5, 8, sleeve);
    pixelRect(ctx, 26, 26 - armSwing, 5, 4, PIXEL_SKIN);

    // head
    pixelRect(ctx, 10, 5, 14, 12, PIXEL_SKIN);

    // eyes — closed for OFFLINE/UNKNOWN (nobody actually working), open
    // otherwise. Drawn without their own outline (too small to read as a
    // block) directly on top of the head fill.
    ctx.fillStyle = PIXEL_INK;
    if (resting) {
      ctx.fillRect(13, 11, 3, 1);
      ctx.fillRect(19, 11, 3, 1);
    } else {
      ctx.fillRect(13, 10, 2, 2);
      ctx.fillRect(19, 10, 2, 2);
    }

    // cap — drawn last so it sits on top of the head, per the layering
    // order (legs -> body -> arms -> head+cap).
    pixelRect(ctx, 9, 2, 16, 5, PIXEL_CAP);
    pixelRect(ctx, 21, 6, 7, 3, PIXEL_CAP);
  }

  // One rAF loop drives every employee canvas on the page — cheap even
  // with many desks (small canvases, simple fillRect/strokeRect calls) and
  // avoids per-employee timers that would drift out of sync with each
  // other.
  function tickEmployeeCanvases(t) {
    document.querySelectorAll('.e-canvas').forEach((canvas) => {
      const ctx = canvas.getContext('2d');
      if (!ctx) return;
      drawPixelEmployee(ctx, canvas.dataset.shirt || '#6ec6ff', canvas.dataset.status || 'UNKNOWN', t);
    });
    requestAnimationFrame(tickEmployeeCanvases);
  }
  requestAnimationFrame(tickEmployeeCanvases);

  function deskSlotHtml(e) {
    const a = e.agent;
    const v = statusVisual(a.status);
    const color = empColor(a.sessionId);
    const name = a.name ? escapeHtml(a.name) : `Session ${shortId(a.sessionId)}`;
    const lastAct = (a.recentActivity || [])[(a.recentActivity || []).length - 1];
    const speech = humanizeActivity(lastAct) || '실시간 작업 내용 없음 (표시 불가)';
    // rawKind is real `claude agents --json` data (interactive vs background)
    // — the crown marks "this is the driving/foreground session", not a
    // Claude-provided leadership role.
    const crown = a.rawKind === 'interactive' ? '<span class="e-crown" title="interactive session — 실제 데이터">👑</span>' : '';
    const roleCaption = e.assignment && e.assignment.source === 'roster' && e.assignment.role
      ? `<div class="employee-role-tag" title="config/agents.json에서 정한 표시용 역할 — Claude Code 제공 값 아님">${escapeHtml(e.assignment.role)}</div>`
      : '';
    return `
      <div class="desk-slot ${e.anim}" data-session-id="${escapeHtml(a.sessionId)}" title="${name} — ${v.label}">
        <div class="employee-wrap">
          <div class="employee-speech">${escapeHtml(speech)}</div>
          ${crown}
          <div class="employee ${v.cls}" style="--emp-shirt:${color}">
            <span class="e-badge">${v.icon}</span>
            <div class="e-ring"></div>
            <canvas class="e-canvas" width="34" height="44"
              data-status="${escapeHtml(a.status || 'UNKNOWN')}"
              data-shirt="${color}"></canvas>
          </div>
        </div>
        <div class="desk"></div>
        <div class="employee-name-tag">${name}</div>
        ${roleCaption}
      </div>
    `;
  }

  // A roster slot with no matching real session — rendered visibly different
  // (dim, sleeping icon, "미출근") from a real employee so it can never be
  // mistaken for an actually-working agent.
  function emptySlotHtml(entry) {
    const label = escapeHtml(entry.displayName || entry.role || entry.id);
    return `
      <div class="desk-slot empty-slot" title="${label} — 미출근(연결된 Claude Code 세션 없음)">
        <div class="employee-wrap">
          <div class="employee status-offline">
            <span class="e-badge">💤</span>
            <canvas class="e-canvas" width="34" height="44"
              data-status="OFFLINE"
              data-shirt="#b9b2a4"></canvas>
          </div>
        </div>
        <div class="desk"></div>
        <div class="employee-name-tag">${label}</div>
        <div class="employee-role-tag">미출근</div>
      </div>
    `;
  }

  function bindDeskClick(container) {
    container.querySelectorAll('.desk-slot[data-session-id]').forEach((el) => {
      el.addEventListener('click', () => openAgentModal(el.dataset.sessionId));
    });
  }

  function roomHtml(dept, list) {
    const rosterEntries = agentRoster.filter((r) => r.department === dept.id);
    const matchedEntryIds = new Set(list.map((e) => e.assignment.entryId).filter(Boolean));
    const emptySlots = rosterEntries.filter((r) => !matchedEntryIds.has(r.id));
    const countLabel = rosterEntries.length ? `${list.length} / ${rosterEntries.length}명` : `${list.length}명`;
    return `
      <div class="room ${dept.room}">
        <div class="room-header">
          <span class="room-label">${dept.icon} ${dept.label}</span>
          <span class="room-count">${countLabel}</span>
        </div>
        <div class="room-desks">
          ${list.map(deskSlotHtml).join('')}
          ${emptySlots.map(emptySlotHtml).join('')}
          ${(list.length + emptySlots.length) === 0 ? '<div class="room-empty">등록된 직원 없음</div>' : ''}
        </div>
      </div>
    `;
  }

  function renderDepartmentRooms(employees) {
    const byDept = { open: [] };
    for (const d of DEPARTMENTS) byDept[d.id] = [];
    for (const e of employees) (byDept[e.assignment.dept] || byDept.open).push(e);

    const rooms = DEPARTMENTS.map((d) => roomHtml(d, byDept[d.id]));
    rooms.push(roomHtml({ id: 'open', room: 'room-open', icon: '🗂️', label: '오픈 오피스 (미배정)' }, byDept.open));
    const floor = $('#office-floor');
    floor.innerHTML = rooms.join('');
    bindDeskClick(floor);
  }

  function renderMissionBoard() {
    const el = $('#office-mission');
    const project = state.project;
    if (!project || !project.phases) {
      el.innerHTML = `
        <div class="mission-board-title">🎯 오늘의 미션</div>
        <div class="empty-note">docs/product/implementation-plan.md를 찾을 수 없어 미션 정보를 표시할 수 없습니다.</div>
      `;
      return;
    }
    const total = project.phases.length;
    const done = project.phases.filter((p) => p.status === 'DONE').length;
    const pct = total ? Math.round((done / total) * 100) : 0;
    const current = project.currentPhase;
    el.innerHTML = `
      <div class="mission-board-title">🎯 오늘의 미션</div>
      <div style="font-weight:700;font-size:12.5px;">${current ? `Phase ${current.number} — ${escapeHtml(phaseDisplayLabel(current))}` : '—'}</div>
      <div class="mission-progress-track"><div class="mission-progress-fill" style="width:${pct}%"></div></div>
      <div class="mission-progress-label">${done} / ${total} Phase 완료 · ${pct}% (docs 기준 실계산, 임의 수치 아님)</div>
      <ul class="mission-phase-list">
        ${project.phases.map((p) => `
          <li class="mission-phase-row ${current && p.number === current.number ? 'current' : ''}">
            <span class="mission-phase-mark ${phaseMarkClass(p.status)}">${phaseMarkSymbol(p.status)}</span>
            <span class="mission-phase-label">Phase ${p.number} — ${escapeHtml(phaseDisplayLabel(p))}</span>
          </li>
        `).join('')}
      </ul>
    `;
  }

  function renderOfficeStatusStrip() {
    const agents = state.agents || [];
    const counts = { working: 0, idle: 0, blocked: 0, error: 0, done: 0, unknown: 0 };
    for (const a of agents) {
      if (a.status === 'WORKING') counts.working += 1;
      else if (a.status === 'WAITING' || a.status === 'REVIEWING') counts.idle += 1;
      else if (a.status === 'BLOCKED') counts.blocked += 1;
      else if (a.status === 'FAILED') counts.error += 1;
      else if (a.status === 'COMPLETED') counts.done += 1;
      else counts.unknown += 1;
    }
    const git = state.git;
    const gitLabel = !git ? '—' : (!git.ok ? '확인불가' : (git.clean ? '클린' : '수정됨'));
    const CMD_LABEL_KO = { RUNNING: '실행중', PASS: '통과', FAIL: '실패' };
    const testStatus = aggregateCmdStatus('test');
    const buildStatus = aggregateCmdStatus('build');
    $('#office-status-strip').innerHTML = `
      <span class="status-strip-item">👥 직원 ${agents.length}</span>
      <span class="status-strip-sep">│</span>
      <span class="status-strip-item"><span class="status-strip-dot dot-working"></span>작업중 ${counts.working}</span>
      <span class="status-strip-item"><span class="status-strip-dot dot-idle"></span>대기 ${counts.idle}</span>
      <span class="status-strip-item"><span class="status-strip-dot dot-blocked"></span>막힘 ${counts.blocked}</span>
      <span class="status-strip-item"><span class="status-strip-dot dot-error"></span>오류 ${counts.error}</span>
      <span class="status-strip-item"><span class="status-strip-dot dot-done"></span>완료 ${counts.done}</span>
      <span class="status-strip-sep">│</span>
      <span class="status-strip-item">Git: ${gitLabel}</span>
      <span class="status-strip-item">Tests: ${testStatus ? CMD_LABEL_KO[testStatus] : '실행 안 함'}</span>
      <span class="status-strip-item">Build: ${buildStatus ? CMD_LABEL_KO[buildStatus] : '실행 안 함'}</span>
    `;
  }

  function officeLogText(l) {
    const bare = l.message.replace(/^\[[a-f0-9]+\]\s*/, '');
    if (l.source === 'agent') {
      if (/Session detected/.test(l.message)) return `👋 ${bare} → 출근`;
      if (/Session ended or no longer visible/.test(l.message)) return `🚪 ${bare} → 퇴근`;
      return `🧑‍💻 ${bare}`;
    }
    if (l.source === 'git') return `📦 ${l.message}`;
    if (l.source === 'test') return `🧪 ${l.message}`;
    if (l.source === 'claude') return `🔌 ${l.message}`;
    if (l.source === 'spawn') return `📨 ${l.message}`;
    return `• ${l.message}`;
  }

  function renderOfficeLogTicker() {
    const rows = (state.logs || []).slice(-60).slice().reverse().slice(0, 15);
    $('#office-log-ticker').innerHTML = rows.length
      ? rows.map((l) => `
        <div class="office-log-row">
          <span class="office-log-ts">${fmtTime(l.ts)}</span>
          <span class="office-log-text">${escapeHtml(officeLogText(l))}</span>
        </div>
      `).join('')
      : '<div class="empty-note">아직 관찰된 활동이 없습니다.</div>';
  }

  function renderOtherSessionsPanel() {
    const list = state.otherSessions || [];
    $('#office-other-sessions').innerHTML = list.length
      ? list.map((a) => `
        <div class="other-session-row"><b>${escapeHtml(a.name || shortId(a.sessionId))}</b> — ${a.status} · ${escapeHtml(a.branch || 'unknown branch')}</div>
      `).join('')
      : '<div class="empty-note">없음</div>';
  }

  function renderOffice() {
    const bridge = state.bridge || {};
    const banner = $('#office-banner');
    if (bridge.claudeAvailable === false) {
      banner.style.display = 'block';
      banner.textContent = '⚠ Claude Code 연결 끊김 — 상태 확인 중 (마지막으로 확인된 직원 상태를 그대로 유지합니다, 임의로 퇴근 처리하지 않습니다)';
    } else {
      banner.style.display = 'none';
    }

    const employees = buildOfficeEmployeeList();
    renderDepartmentRooms(employees);
    renderMissionBoard();
    renderOfficeStatusStrip();
    renderOfficeLogTicker();
    renderOtherSessionsPanel();
  }

  function tickClock() {
    const el = $('#office-clock');
    if (el) el.textContent = new Date().toLocaleTimeString('ko-KR', { hour12: false });
  }
  setInterval(tickClock, 1000);
  tickClock();

  // Roster is a small user-editable file, not part of the SSE state stream —
  // polled independently so edits to config/agents.json apply without a
  // dashboard reload.
  fetchAgentRoster();
  setInterval(fetchAgentRoster, 30000);

  // Elapsed-time labels drift, so re-render periodically even without new
  // state — this does NOT invent new data, just recomputes "Xs ago" labels
  // and speech-bubble text from timestamps/activity already held in state.
  setInterval(() => {
    if ($('#view-agents').classList.contains('active')) renderAgents();
    if ($('#view-overview').classList.contains('active')) renderOverview();
    renderOffice();
  }, 5000);

  connect();
})();
