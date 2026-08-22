/* ONDAM Guardian — Phase 41 prototype. Screen templates (pure functions -> HTML strings). */

const TABS = [
  { key: 'home', label: '홈', route: '#/home', icon: 'home' },
  { key: 'notifications', label: '알림', route: '#/notifications', icon: 'bell', badge: true },
  { key: 'records', label: '기록', route: '#/records', icon: 'record' },
  { key: 'statistics', label: '통계', route: '#/statistics', icon: 'stats' },
  { key: 'more', label: '더보기', route: '#/more', icon: 'more' },
];

function appbar({ title, back }) {
  return `<div class="appbar">
    ${back ? `<button class="appbar-btn" data-nav="${back}" aria-label="뒤로 가기">${icon('back')}</button>` : '<span style="width:var(--touch-min)"></span>'}
    <div class="appbar-title">${title}</div>
    <span style="width:var(--touch-min)"></span>
  </div>`;
}

function tabShell(body, activeTab) {
  return `<div class="screen">
    ${body}
    <nav class="bottomnav">
      ${TABS.map(t => `<button class="bottomnav-item ${t.key===activeTab?'active':''}" data-nav="${t.route}">
        ${t.badge && unreadCount() ? '<span class="nav-dot"></span>' : ''}
        ${icon(t.icon)}<span>${t.label}</span>
      </button>`).join('')}
    </nav>
  </div>`;
}

function stackShell({ title, back }, bodyHtml, opts) {
  opts = opts || {};
  return `<div class="screen">
    ${appbar({ title, back })}
    <div class="screen-body">${bodyHtml}</div>
    ${opts.fixedBottom ? `<div class="btn-fixed-bottom">${opts.fixedBottom}</div>` : ''}
  </div>`;
}

function riskIcon(risk) { return risk === 'danger' ? 'danger' : risk === 'warning' ? 'warning' : 'safe'; }
function riskBadgeClass(risk) { return risk === 'danger' ? 'badge-danger' : risk === 'warning' ? 'badge-warning' : 'badge-safe'; }

/* ---------- Common Analysis Detail (Phase 39-B structure, minus the Senior-only voice-question step) ---------- */
function renderAnalysisResult(a, backRoute) {
  return stackShell({ title: '분석 상세', back: backRoute }, `
    <div class="stack">
      <div class="row"><span class="badge badge-lg ${riskBadgeClass(a.risk)}">${icon(riskIcon(a.risk))}${a.riskLabel}</span></div>
      <div class="muted">${a.date} · ${a.elder} · ${a.title}</div>

      ${a.due ? `<div class="card" style="background:var(--color-surface-alt);border:none;">
        <div class="muted">${a.dueLabel}</div>
        <div class="h2" style="margin:0;">${icon('calendar')} ${a.due}</div>
      </div>` : ''}

      <div class="card">
        <div class="h3">AI가 정리한 핵심</div>
        <ol style="margin:0;padding-left:20px;">
          ${a.summary.map(line => `<li class="body-text" style="margin-bottom:6px;">${line}</li>`).join('')}
        </ol>
      </div>

      <div class="card">
        <div class="h3">해야 할 일</div>
        ${a.todos.map((t, idx) => `
          <button class="check-item ${t.checked ? 'checked' : ''}" style="width:100%;background:none;border:none;text-align:left;" data-action="toggleTodo" data-args="${a.id}|${idx}">
            <span class="check-box">${t.checked ? icon('safe') : ''}</span>
            <span class="check-text body-text">${t.text}</span>
          </button>`).join('')}
      </div>

      <details class="detail-block card" ${a.detailOpen ? 'open' : ''}>
        <summary data-action="toggleDetail" data-args="${a.id}">상세정보 보기 ${icon('chev')}</summary>
        <div class="kv-row"><span class="muted">신뢰도</span><span>${a.confidence}%</span></div>
        ${a.structured.map(s => `<div class="kv-row"><span class="muted">${s.k}</span><span>${s.v}</span></div>`).join('')}
        <div class="divider"></div>
        <div class="muted" style="margin-bottom:4px;">원문</div>
        <div class="body-text" style="white-space:pre-wrap;">${a.rawText}</div>
      </details>
    </div>
  `, {
    fixedBottom: a.confirmed
      ? `<div class="banner-success">${icon('safe')} 확인 완료했어요</div>`
      : `<button class="btn btn-primary" data-action="confirmAnalysis" data-args="${a.id}">확인 완료</button>`
  });
}

function notifCard(n) {
  return `<button class="card card-tap notif-card ${n.unread ? 'unread' : ''}" data-action="markRead" data-args="${n.id}" data-nav="#/detail/${n.analysisId}?back=${encodeURIComponent('#/notifications')}">
    <div class="row" style="justify-content:space-between;">
      <span class="badge ${riskBadgeClass(n.risk)}">${icon(riskIcon(n.risk))}${n.risk === 'danger' ? '위험' : n.risk === 'warning' ? '확인 필요' : '안전'}</span>
      ${n.unread ? `<span class="unread-chip">새 알림</span>` : `<span class="read-chip">확인함</span>`}
    </div>
    <div class="h3" style="margin:6px 0 2px;">${n.title}</div>
    <div class="muted">${n.summary}</div>
    <div class="muted" style="margin-top:4px;">${n.elder} · ${n.time}</div>
  </button>`;
}

function recordCard(a) {
  return `<button class="card card-tap" data-nav="#/detail/${a.id}?back=${encodeURIComponent('#/records')}">
    <div class="row" style="justify-content:space-between;">
      <span class="muted">${a.date}</span>
      <span class="badge ${riskBadgeClass(a.risk)}">${icon(riskIcon(a.risk))}${a.riskLabel}</span>
    </div>
    <div class="h3" style="margin:4px 0 2px;">${a.title}</div>
    <div class="muted">${a.elder}</div>
    <div class="muted" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${a.summary[0]}</div>
  </button>`;
}

function emptyElderState() {
  return `<div class="state-block">
  ${icon('person')}
  <div class="h3">아직 연결된 어르신이 없습니다.</div>
  <div class="muted">어르신과 연결하면 알림과 기록을 확인할 수 있어요.</div>
  <button class="btn btn-primary" style="margin-top:var(--space-md);" data-nav="#/connection">${icon('qr')} 어르신 연결하기</button>
</div>`;
}

/* ---------- Screens ---------- */
const Screens = {
  render(path, params) {
    const segs = path.replace(/^#\//, '').split('/').filter(Boolean);
    const root = segs[0] || 'login';

    if (root === 'login') return this.login();
    if (root === 'pin-forgot') return this.pinForgot();
    if (root === 'home') return this.home();
    if (root === 'notifications') return this.notifications();
    if (root === 'records') return this.records();
    if (root === 'statistics') return this.statistics();
    if (root === 'connection') return this.connection();
    if (root === 'more') return this.more();
    if (root === 'settings') return this.settings();
    if (root === 'support') return this.support();
    if (root === 'privacy') return this.privacy();
    if (root === 'states') return this.statesDemo();

    if (root === 'detail' && segs[1]) {
      const backRoute = params.get('back') || '#/home';
      if (params.get('loading')) return this.analysisLoading(backRoute);
      return renderAnalysisResult(State.analysis[segs[1]], backRoute);
    }

    return this.login();
  },

  /* 1. 로그인 — Senior와 동일하게 휴대폰+PIN 단일 화면. 역할 선택/별도 PIN 화면 없음 */
  login() {
    const step = !State.phoneDraft ? 'phone' : 'pin';
    const pinLabel = State.hasPin ? 'PIN 번호를 입력해주세요' : 'PIN 번호를 새로 만들어주세요 (4자리)';
    return `<div class="screen">
      <div class="screen-body" style="display:flex;flex-direction:column;justify-content:center;">
        <div class="stack" style="text-align:center;margin-bottom:var(--space-xl);">
          <div class="h1">온담</div>
          <div class="muted">가족(보호자)으로 휴대폰 번호와 PIN으로 시작해요</div>
        </div>
        ${step === 'phone' ? `
          <div class="field">
            <label for="phone">휴대폰 번호</label>
            <input id="phone" class="input" inputmode="numeric" placeholder="010-0000-0000" data-bind="phone.value" value="${State.phoneDraft}">
          </div>
          <button class="btn btn-primary" data-action="confirmPhone">시작하기</button>
        ` : `
          <div class="body-text" style="text-align:center;">${pinLabel}</div>
          <div class="pin-dots">${[0,1,2,3].map(i => `<span class="pin-dot ${State.pinDraft.length>i?'filled':''}"></span>`).join('')}</div>
          <div class="keypad">
            ${[1,2,3,4,5,6,7,8,9].map(n => `<button data-action="setPinDigit" data-args="${n}">${n}</button>`).join('')}
            <button class="btn-ghost" data-action="resetPhone">번호 다시</button>
            <button data-action="setPinDigit" data-args="0">0</button>
            <button class="btn-ghost" data-action="pinBackspace">지우기</button>
          </div>
          <button class="btn btn-ghost" data-nav="#/pin-forgot" style="margin-top:var(--space-md);">${icon('lock')} 비밀번호를 잊으셨나요?</button>
        `}
      </div>
    </div>`;
  },

  pinForgot() {
    return stackShell({ title: 'PIN 재설정', back: '#/login' }, `
      <div class="state-block">
        ${icon('lock')}
        <div class="h3">휴대폰 인증 후 PIN을 다시 만들 수 있어요.</div>
        <div class="muted">등록된 휴대폰 번호로 인증하면 새 PIN을 설정할 수 있어요.</div>
      </div>
      <button class="btn btn-primary" data-action="requestPinReset">인증하고 PIN 다시 설정하기</button>
    `);
  },

  /* 2. 홈 — 모니터링 중심: 연결된 어르신 상태 / 최근 활동 / 최근 알림 */
  home() {
    const elders = State.connectedElders;
    const e = activeElder();
    const body = `<div class="screen-body">
      <div class="row" style="justify-content:space-between;">
        <div class="h2" style="margin:0;">홈</div>
        <button class="chip" data-action="toggleElderDemo">${elders.length ? '연결된 어르신 없음 보기 (예시)' : '연결 예시 다시 보기'}</button>
      </div>

      ${!elders.length ? emptyElderState() : `
        ${elders.length > 1 ? `<div class="elder-switch" style="margin:var(--space-sm) 0;">
          ${elders.map(x => `<button class="elder-chip ${x.id===e.id?'active':''}" data-action="switchElder" data-args="${x.id}">${x.name}</button>`).join('')}
        </div>` : ''}

        <div class="elder-status-card ${e.status}">
          ${icon(e.status === 'safe' ? 'safe' : 'warning')}
          <div class="h2" style="margin:8px 0 2px;">${e.status === 'safe' ? '안심 상태예요' : '주의가 필요해요'}</div>
          <div class="body-text">${e.name}</div>
        </div>

        <div class="h3" style="margin-top:var(--space-lg);">최근 활동</div>
        <div class="card"><div class="body-text">${e.lastActivity}</div></div>

        <div class="row" style="justify-content:space-between;margin-top:var(--space-lg);">
          <div class="h3" style="margin:0;">최근 알림</div>
          <button class="chip" data-nav="#/notifications">전체보기</button>
        </div>
        <div class="stack">${State.notifications.slice(0,2).map(notifCard).join('')}</div>
      `}
    </div>`;
    return tabShell(body, 'home');
  },

  /* 3. 알림 — 실시간 알림 / 위험 기록 두 영역 구분, 미확인 알림은 아이콘+배지+테두리로 표시 */
  notifications() {
    const realtime = State.notifications.filter(n => n.category === 'realtime');
    const risk = State.notifications.filter(n => n.category === 'risk');
    const body = `<div class="screen-body">
      <div class="h2">알림</div>
      <div class="section-label">실시간 알림</div>
      ${realtime.length ? `<div class="stack">${realtime.map(notifCard).join('')}</div>` : `<div class="state-block">${icon('bell')}<div>새로운 알림이 없어요.</div></div>`}
      <div class="section-label">위험 기록</div>
      ${risk.length ? `<div class="stack">${risk.map(notifCard).join('')}</div>` : `<div class="state-block">${icon('bell')}<div>위험 기록이 없어요.</div></div>`}
    </div>`;
    return tabShell(body, 'notifications');
  },

  analysisLoading(backRoute) {
    return stackShell({ title: '불러오는 중', back: backRoute }, `
      <div class="loading-wrap">
        <div class="spinner"></div>
        <div class="h3">데이터를 불러오는 중입니다.</div>
        <div class="progress-bar"><div style="width:70%"></div></div>
      </div>
    `);
  },

  /* 4. 기록 */
  records() {
    const list = fmtRecordsList();
    const body = `<div class="screen-body">
      <div class="h2">기록</div>
      ${list.length ? `<div class="stack">${list.map(recordCard).join('')}</div>` : `<div class="state-block">${icon('record')}<div>아직 기록이 없어요.</div></div>`}
    </div>`;
    return tabShell(body, 'records');
  },

  /* 5. 통계 */
  statistics() {
    const s = State.feeStats;
    const body = `<div class="screen-body">
      <div class="h2">이용 통계</div>
      <div class="muted" style="margin-bottom:var(--space-md);">${activeElder() ? activeElder().name : '어르신'} 기준</div>
      <div class="grid-2">
        <div class="card"><div class="muted">분석 건수</div><div class="h2" style="margin:0;">${s.analysisCount}건</div></div>
        <div class="card"><div class="muted">위험 분석 건수</div><div class="h2" style="margin:0;">${s.riskCount}건</div></div>
        <div class="card"><div class="muted">총 요금</div><div class="h2" style="margin:0;">${s.total.toLocaleString()}원</div></div>
        <div class="card"><div class="muted">평균 요금</div><div class="h2" style="margin:0;">${s.avg.toLocaleString()}원</div></div>
        <div class="card"><div class="muted">최고 요금</div><div class="h2" style="margin:0;">${s.max.toLocaleString()}원</div></div>
        <div class="card"><div class="muted">최저 요금</div><div class="h2" style="margin:0;">${s.min.toLocaleString()}원</div></div>
      </div>
      <div class="card">
        <div class="h3">월별 통계</div>
        <div class="muted">${s.monthly}</div>
      </div>
      <div class="card">
        <div class="h3">연별 통계</div>
        <div class="muted">${s.yearly}</div>
      </div>
    </div>`;
    return tabShell(body, 'statistics');
  },

  /* 연결된 어르신 */
  connection() {
    return stackShell({ title: '연결된 어르신', back: '#/more' }, `
      <button class="btn btn-primary" style="margin-bottom:var(--space-lg);">${icon('qr')} QR로 어르신 연결하기 (예시)</button>

      ${State.connectedElders.length ? `
        <div class="h3">연결된 어르신</div>
        <div class="stack">
          ${State.connectedElders.map(e => `
            <div class="card">
              <div class="row" style="justify-content:space-between;">
                <span class="h3" style="margin:0;">${e.name}</span>
                <span class="chip">연결됨</span>
              </div>
              <div class="muted" style="margin:4px 0 8px;">${e.lastActivity}</div>
              <button class="btn btn-danger" data-action="disconnectElder" data-args="${e.id}">연결 해제</button>
            </div>
          `).join('')}
        </div>
      ` : emptyElderState()}

      ${State.pendingElders.length ? `
        <div class="h3" style="margin-top:var(--space-lg);">연결 대기중</div>
        <div class="stack">
          ${State.pendingElders.map((p, idx) => `
            <div class="card row" style="justify-content:space-between;">
              <span class="body-text">${p.name}</span>
              <span class="row">
                <button class="btn btn-primary" style="width:auto;padding:0 12px;min-height:36px;" data-action="respondPending" data-args="${idx}|1">수락</button>
                <button class="btn btn-ghost" style="width:auto;padding:0 12px;min-height:36px;" data-action="respondPending" data-args="${idx}|0">거절</button>
              </span>
            </div>
          `).join('')}
        </div>
      ` : ''}
    `);
  },

  more() {
    const items = [
      { label: '연결된 어르신', route: '#/connection', icon: 'qr' },
      { label: '설정', route: '#/settings', icon: 'more' },
      { label: '고객 지원', route: '#/support', icon: 'support' },
    ];
    const body = `<div class="screen-body">
      <div class="h2">더보기</div>
      <div class="stack" style="gap:0;">
        ${items.map(i => `<button class="card-tap row" style="justify-content:space-between;padding:var(--space-md);border-radius:var(--radius-md);margin-bottom:var(--space-sm);" data-nav="${i.route}">
          <span class="row">${icon(i.icon)} <span class="body-text">${i.label}</span></span>
          ${icon('chev')}
        </button>`).join('')}
      </div>
      <div class="divider"></div>
      <button class="btn btn-ghost" data-nav="#/states">화면 상태 예시 (Loading / Empty / Error)</button>
    </div>`;
    return tabShell(body, 'more');
  },

  /* 최소 구성: 로그아웃/회원탈퇴 + 향후 확장을 위한 비활성 placeholder 한 줄 */
  settings() {
    return stackShell({ title: '설정', back: '#/more' }, `
      <div class="card">
        <div class="row" style="justify-content:space-between;">
          <span class="body-text">위험 알림 설정</span>
          <span class="muted">준비 중</span>
        </div>
      </div>
      <button class="btn btn-secondary" data-action="logout" data-nav="#/login">로그아웃</button>
      <button class="btn btn-danger" data-action="deleteAccount" data-nav="#/login">회원 탈퇴</button>
    `);
  },

  support() {
    return stackShell({ title: '고객 지원', back: '#/more' }, `
      <div class="card row" style="justify-content:space-between;"><span class="body-text">${icon('support')} 고객센터 연락처</span><span class="muted">준비 중</span></div>
      <button class="card card-tap row" style="justify-content:space-between;" data-nav="#/privacy">
        <span class="body-text">${icon('lock')} 개인정보 보관 안내</span>${icon('chev')}
      </button>
    `);
  },
  privacy() {
    const items = ['수집 항목', '이용 목적', '보관 기간', '제3자 제공 여부', '이용자 권리'];
    return stackShell({ title: '개인정보 보관 안내', back: '#/support' }, `
      <div class="stack">${items.map(t => `<div class="card"><div class="h3">${t}</div><div class="muted">안내 내용이 여기에 표시돼요.</div></div>`).join('')}</div>
    `);
  },

  /* 디자인 검토용 상태 예시 모음: Loading / Empty / Error */
  statesDemo() {
    return stackShell({ title: '화면 상태 예시', back: '#/more' }, `
      <div class="h3">Loading</div>
      <div class="card loading-wrap" style="padding:var(--space-lg);">
        <div class="spinner"></div>
        <div class="body-text">데이터를 불러오는 중입니다.</div>
      </div>

      <div class="h3">Empty</div>
      <div class="card state-block">
        ${icon('person')}
        <div>연결된 어르신이 없습니다.</div>
      </div>

      <div class="h3">Error</div>
      <div class="card state-block">
        ${icon('warning')}
        <div>정보를 불러오지 못했습니다.<br>다시 시도해 주세요.</div>
        <button class="btn btn-secondary" style="margin-top:var(--space-md);">${icon('refresh')} 다시 시도</button>
      </div>
    `);
  },
};
