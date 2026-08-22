/* ONDAM Senior — Phase 40 prototype. Screen templates (pure functions -> HTML strings). */

const TABS = [
  { key: 'info', label: '정보', route: '#/info', icon: 'info' },
  { key: 'home', label: '홈', route: '#/home', icon: 'home' },
  { key: 'records', label: '기록', route: '#/records', icon: 'record' },
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
    <button class="fab-voice" data-nav="#/voice" aria-label="음성 비서">${icon('mic')}</button>
    <nav class="bottomnav">
      ${TABS.map(t => `<button class="bottomnav-item ${t.key===activeTab?'active':''}" data-nav="${t.route}">
        ${icon(t.icon)}<span>${t.label}</span>
      </button>`).join('')}
    </nav>
  </div>`;
}

function stackShell({ title, back }, bodyHtml, opts) {
  opts = opts || {};
  return `<div class="screen">
    ${appbar({ title, back })}
    <div class="screen-body ${opts.noPad ? 'no-pad' : ''}">${bodyHtml}</div>
    ${opts.fixedBottom ? `<div class="btn-fixed-bottom">${opts.fixedBottom}</div>` : ''}
  </div>`;
}

function riskIcon(risk) { return risk === 'danger' ? 'danger' : risk === 'warning' ? 'warning' : 'safe'; }
function riskBadgeClass(risk) { return risk === 'danger' ? 'badge-danger' : risk === 'warning' ? 'badge-warning' : 'badge-safe'; }

/* ---------- Common Analysis Result (shared by document/message/record detail) ---------- */
function renderAnalysisResult(a, backRoute) {
  return stackShell({ title: a.kind === 'document' ? '문서 분석 결과' : '문자 분석 결과', back: backRoute }, `
    <div class="stack">
      <div class="row"><span class="badge badge-lg ${riskBadgeClass(a.risk)}">${icon(riskIcon(a.risk))}${a.riskLabel}</span></div>
      <div class="muted">${a.date} · ${a.title}</div>

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

      <button class="btn btn-secondary" data-nav="#/voice?about=${a.id}">${icon('mic')} 이 내용 물어보기</button>
    </div>
  `, {
    fixedBottom: a.confirmed
      ? `<div class="banner-success">${icon('safe')} 확인 완료했어요</div>`
      : `<button class="btn btn-primary" data-action="confirmAnalysis" data-args="${a.id}">확인 완료</button>`
  });
}

/* ---------- Screens ---------- */
const Screens = {
  render(path, params) {
    const segs = path.replace(/^#\//, '').split('/').filter(Boolean);
    const root = segs[0] || 'login';

    if (root === 'login') return this.login();
    if (root === 'home') return this.home();
    if (root === 'info') return this.info();
    if (root === 'voice') return this.voice(params);
    if (root === 'easy-home') return this.easyHome();
    if (root === 'emergency') return this.emergency();

    if (root === 'document') {
      if (segs[1] === 'preview') return this.documentPreview();
      if (segs[1] === 'result') return params.get('loading') ? this.analysisLoading('document','#/document/preview') : renderAnalysisResult(State.analysis['doc-1'], '#/document/preview');
      return this.documentCamera();
    }
    if (root === 'message') {
      if (segs[1] === 'detail') return this.messageDetail(segs[2]);
      if (segs[1] === 'result') return params.get('loading') ? this.analysisLoading('message','#/message/detail/sms-1') : renderAnalysisResult(State.analysis['msg-1'], '#/message/detail/sms-1');
      return this.messageList();
    }
    if (root === 'records') {
      if (segs[1]) return renderAnalysisResult(State.analysis[segs[1]], '#/records');
      return this.records();
    }

    if (root === 'more') return this.more();
    if (root === 'settings') return this.settings();
    if (root === 'profile') return this.profile();
    if (root === 'statistics') return this.statistics();
    if (root === 'connection') return this.connection();
    if (root === 'welfare') return this.welfare();
    if (root === 'support') return this.support();
    if (root === 'privacy') return this.privacy();
    if (root === 'onboarding') return this.onboarding();

    return this.login();
  },

  /* 1. 로그인 — 휴대폰+PIN 단일 화면, 신규가입/로그인/PIN최초설정/PIN확인 모두 처리 */
  login() {
    const step = !State.phoneDraft ? 'phone' : 'pin';
    const pinLabel = State.hasPin ? 'PIN 번호를 입력해주세요' : 'PIN 번호를 새로 만들어주세요 (4자리)';
    return `<div class="screen">
      <div class="screen-body" style="display:flex;flex-direction:column;justify-content:center;">
        <div class="stack" style="text-align:center;margin-bottom:var(--space-xl);">
          <div class="h1">온담</div>
          <div class="muted">휴대폰 번호와 PIN으로 시작해요</div>
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

  /* 2. 홈 */
  home() {
    const body = `<div class="screen-body">
      <div class="row" style="justify-content:space-between;">
        <div class="h2" style="margin:0;">안녕하세요</div>
        <button class="chip" data-nav="#/easy-home">쉬운 모드로 보기</button>
      </div>
      <div class="feature-grid" style="margin:var(--space-md) 0;">
        <button class="feature-card" data-nav="#/document">${icon('doc')}<div class="h3" style="margin:0;">문서 읽기</div><div class="muted">사진 찍고 바로 확인</div></button>
        <button class="feature-card" data-nav="#/message">${icon('message')}<div class="h3" style="margin:0;">문자 확인</div><div class="muted">위험한 문자 걸러내기</div></button>
        <button class="feature-card" data-nav="#/welfare">${icon('location')}<div class="h3" style="margin:0;">경로당 찾기</div><div class="muted">가까운 경로당 찾기</div></button>
        <button class="feature-card" data-nav="#/records">${icon('record')}<div class="h3" style="margin:0;">내 기록</div><div class="muted">지난 확인 내역</div></button>
      </div>
      <button class="emergency-btn" data-nav="#/emergency">${icon('phone')} 긴급 도움 요청</button>

      <div class="h3" style="margin-top:var(--space-lg);">최근 기록</div>
      ${fmtRecordsList().slice(0,2).map(recordCard).join('')}
    </div>`;
    return tabShell(body, 'home');
  },

  info() {
    const body = `<div class="screen-body">
      <div class="h2">정보</div>
      <div class="state-block">
        <div class="icon">${icon('info')}</div>
        <div>아직 준비 중이에요.</div>
      </div>
    </div>`;
    return tabShell(body, 'info');
  },

  /* Easy Mode 홈: 정보량 최소화, 화면당 단일 핵심 CTA 4개만 */
  easyHome() {
    return `<div class="screen">
      <div class="appbar">
        <span style="width:var(--touch-min)"></span>
        <div class="appbar-title">쉬운 모드</div>
        <button class="appbar-btn" data-nav="#/home" aria-label="일반 모드로">${icon('close')}</button>
      </div>
      <div class="easy-grid">
        <button class="easy-btn primary" data-nav="#/document">${icon('doc')} 문서 읽기</button>
        <button class="easy-btn" data-nav="#/message">${icon('message')} 문자 확인</button>
        <button class="easy-btn" data-nav="#/records">${icon('record')} 내 기록</button>
        <button class="easy-btn" data-nav="#/emergency" style="background:var(--color-danger-bg);color:var(--color-danger);">${icon('phone')} 도움 요청</button>
      </div>
    </div>`;
  },

  emergency() {
    return stackShell({ title: '긴급 도움', back: '#/home' }, `
      <div class="stack" style="text-align:center;padding-top:var(--space-xl);">
        ${State.emergencySent ? `
          <div class="banner-success" style="font-size:var(--font-size-lg);">${icon('safe')} 보호자에게 연락했어요</div>
          <div class="muted">잠시만 기다려주세요.</div>
        ` : `
          <div class="body-text">버튼을 누르면 등록된 보호자에게<br>바로 알림이 전송돼요.</div>
          <button class="emergency-btn" style="min-height:96px;font-size:var(--font-size-xl);" data-action="sendEmergency">${icon('phone')} 지금 도움 요청하기</button>
        `}
      </div>
    `);
  },

  voice(params) {
    const about = params.get('about');
    return stackShell({ title: '음성 비서', back: '#/home' }, `
      <div class="loading-wrap">
        <div class="spinner"></div>
        <div class="h3">${about ? '이 내용에 대해 말씀해주세요' : '무엇을 도와드릴까요?'}</div>
        <div class="muted">마이크 버튼을 누르고 말씀해주세요</div>
        <button class="btn btn-primary" style="max-width:200px;" data-nav="#/home">${icon('mic')} 듣는 중</button>
      </div>
    `);
  },

  /* 3. 문서 촬영 */
  documentCamera() {
    return stackShell({ title: '문서 촬영', back: '#/home' }, `
      <div class="camera-view">
        <div style="text-align:center;">
          ${icon('camera')}
          <div class="muted" style="color:#cfcfcf;margin-top:8px;">문서를 화면 안에 맞춰주세요</div>
        </div>
        <button class="appbar-btn" style="position:absolute;top:8px;right:8px;color:#fff;" aria-label="플래시">${icon('flash')}</button>
      </div>
      <button class="shutter-btn" aria-label="촬영" data-action="addPhoto"></button>
      ${State.docPhotos.length ? `<div class="muted" style="text-align:center;">${State.docPhotos.length}장 촬영됨</div>` : ''}
    `, { fixedBottom: `<button class="btn btn-primary" ${State.docPhotos.length ? '' : 'disabled'} data-nav="#/document/preview">다음</button>` });
  },
  documentPreview() {
    return stackShell({ title: '촬영한 사진', back: '#/document' }, `
      <div class="photo-grid">
        ${State.docPhotos.map((p,i) => `<div class="photo-thumb">문서 ${i+1}
          <button class="remove" aria-label="삭제" data-action="removePhoto" data-args="${p.id}">${icon('close')}</button>
        </div>`).join('')}
      </div>
      ${!State.docPhotos.length ? `<div class="state-block">${icon('doc')}<div>촬영된 사진이 없어요.</div></div>` : ''}
      <button class="btn btn-secondary" style="margin-top:var(--space-md);" data-nav="#/document">${icon('camera')} 추가 촬영</button>
    `, { fixedBottom: `<button class="btn btn-primary" ${State.docPhotos.length ? '' : 'disabled'} data-action="startAnalysis" data-args="doc-1|#/document/result">분석하기</button>` });
  },

  analysisLoading(kind, backRoute) {
    return stackShell({ title: kind === 'document' ? '문서 분석 중' : '문자 분석 중', back: backRoute }, `
      <div class="loading-wrap">
        <div class="spinner"></div>
        <div class="h3">AI가 내용을 확인하고 있어요</div>
        <div class="progress-bar"><div style="width:70%"></div></div>
        <div class="muted">잠시만 기다려주세요</div>
      </div>
    `);
  },

  /* 4. 문자 확인 */
  messageList() {
    return stackShell({ title: '문자 확인', back: '#/home' }, `
      <div class="stack">
        ${State.messages.map(m => `
          <button class="card card-tap" data-nav="#/message/detail/${m.id}">
            <div class="row" style="justify-content:space-between;">
              <div class="h3" style="margin:0;">${m.sender}</div>
              <div class="muted">${m.date}</div>
            </div>
            <div class="muted" style="margin-top:4px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${m.preview}</div>
          </button>
        `).join('')}
      </div>
    `);
  },
  messageDetail(id) {
    const m = State.messages.find(x => x.id === id) || State.messages[0];
    return stackShell({ title: '문자 상세', back: '#/message' }, `
      <div class="card">
        <div class="row" style="justify-content:space-between;">
          <div class="h3" style="margin:0;">${m.sender}</div>
          <div class="muted">${m.date}</div>
        </div>
        <div class="divider"></div>
        <div class="body-text">${m.preview}</div>
      </div>
    `, { fixedBottom: `<button class="btn btn-primary" data-action="startAnalysis" data-args="msg-1|#/message/result">분석하기</button>` });
  },

  /* 5/6/기록상세 은 renderAnalysisResult 공용 컴포넌트 사용 (router에서 처리) */

  /* 6. 기록 */
  records() {
    const body = `<div class="screen-body">
      <div class="h2">내 기록</div>
      ${fmtRecordsList().length ? `<div class="stack">${fmtRecordsList().map(recordCard).join('')}</div>` : `
        <div class="state-block">${icon('record')}<div>아직 기록이 없어요.</div></div>
      `}
    </div>`;
    return tabShell(body, 'records');
  },

  more() {
    const items = [
      { label: '내 정보', route: '#/profile', icon: 'info' },
      { label: '연결된 보호자', route: '#/connection', icon: 'qr' },
      { label: '이용 통계', route: '#/statistics', icon: 'stats' },
      { label: '설정', route: '#/settings', icon: 'more' },
      { label: '경로당 찾기', route: '#/welfare', icon: 'location' },
      { label: '이용 방법 안내', route: '#/onboarding', icon: 'info' },
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
    </div>`;
    return tabShell(body, 'more');
  },

  settings() {
    return stackShell({ title: '설정', back: '#/more' }, `
      <div class="stack">
        <div class="card">
          <div class="toggle-row"><span class="body-text">쉬운 모드</span>
            <button class="toggle ${State.easyMode?'on':''}" data-action="toggleEasy" aria-label="쉬운 모드"></button>
          </div>
          <div class="divider"></div>
          <div class="body-text" style="margin-bottom:8px;">글자 크기</div>
          <input type="range" min="1" max="1.3" step="0.15" value="${State.fontScale}" data-font-scale style="width:100%;">
          <div class="row" style="justify-content:space-between;"><span class="muted">보통</span><span class="muted">크게</span><span class="muted">아주 크게</span></div>
          <div class="divider"></div>
          <div class="body-text" style="margin-bottom:8px;">언어</div>
          <select class="input" data-language>
            <option value="ko" ${State.language==='ko'?'selected':''}>한국어</option>
            <option value="en" ${State.language==='en'?'selected':''}>English</option>
            <option value="zh" ${State.language==='zh'?'selected':''}>中文</option>
            <option value="ja" ${State.language==='ja'?'selected':''}>日本語</option>
          </select>
        </div>
        <button class="btn btn-secondary" data-action="logout" data-nav="#/login">로그아웃</button>
        <button class="btn btn-danger" data-action="deleteAccount" data-nav="#/login">회원 탈퇴</button>
      </div>
    `);
  },

  profile() {
    return stackShell({ title: '내 정보', back: '#/more' }, `
      <div class="field"><label>이름</label><input class="input" value="${State.user.name}" data-bind="profile.name" placeholder="이름을 입력해주세요"></div>
      <div class="field"><label>나이</label><input class="input" inputmode="numeric" value="${State.user.age}" data-bind="profile.age" placeholder="나이를 입력해주세요"></div>
      <div class="field"><label>내 지역</label>
        <input class="input" value="${State.user.region}" data-bind="profile.region" placeholder="지역을 입력해주세요">
      </div>
      <button class="btn btn-secondary" data-action="useCurrentLocation">${icon('location')} 현재 위치로 자동 입력</button>
      <div class="muted" style="margin-top:var(--space-md);">* 저장 기능은 준비 중이에요 (프로토타입)</div>
    `, { fixedBottom: `<button class="btn btn-primary">저장</button>` });
  },

  statistics() {
    return stackShell({ title: '이용 통계', back: '#/more' }, `
      <div class="grid-2">
        <div class="card"><div class="muted">총 금액</div><div class="h2" style="margin:0;">312,400원</div></div>
        <div class="card"><div class="muted">평균 금액</div><div class="h2" style="margin:0;">104,100원</div></div>
        <div class="card"><div class="muted">최고 금액</div><div class="h2" style="margin:0;">132,400원</div></div>
        <div class="card"><div class="muted">최저 금액</div><div class="h2" style="margin:0;">45,300원</div></div>
      </div>
      <div class="card">
        <div class="h3">월별 통계</div>
        <div class="muted">6월 · 7월 · 8월 확인 건수: 1 / 2 / 3건</div>
      </div>
      <div class="card">
        <div class="h3">연별 통계</div>
        <div class="muted">2026년 확인 건수: 6건</div>
      </div>
    `);
  },

  connection() {
    return stackShell({ title: '연결된 보호자', back: '#/more' }, `
      <button class="btn btn-primary" data-nav="#/connection">${icon('qr')} QR로 보호자 연결하기</button>
      <div class="h3" style="margin-top:var(--space-lg);">보호자 목록</div>
      <div class="stack">
        ${State.guardians.map((g, idx) => `
          <div class="card row" style="justify-content:space-between;">
            <span class="body-text">${g.name}</span>
            ${g.status === 'accepted'
              ? `<span class="chip">연결됨</span>`
              : `<span class="row">
                  <button class="btn btn-primary" style="width:auto;padding:0 12px;min-height:36px;" data-action="connectGuardianRespond" data-args="${idx}|1">수락</button>
                  <button class="btn btn-ghost" style="width:auto;padding:0 12px;min-height:36px;" data-action="connectGuardianRespond" data-args="${idx}|0">거절</button>
                </span>`}
          </div>
        `).join('')}
      </div>
    `);
  },

  welfare() {
    return stackShell({ title: '경로당 찾기', back: '#/home' }, `
      <div class="field"><label>내 지역</label><input class="input" value="${State.user.region || '서울특별시 은평구 OO동'}" readonly></div>
      <div class="h3">주변 경로당</div>
      <div class="stack">
        ${State.welfareCenters.map(w => `
          <div class="card">
            <div class="row" style="justify-content:space-between;">
              <div class="h3" style="margin:0;">${w.name}</div>
              <span class="chip">${w.distance}</span>
            </div>
            <div class="muted">${w.address}</div>
            <a class="btn btn-secondary" style="margin-top:8px;" href="tel:${w.phone}">${icon('phone')} 전화하기</a>
          </div>
        `).join('')}
      </div>
      <div class="muted">* 실제 데이터 연동 전 예시 화면이에요.</div>
    `);
  },

  support() {
    return stackShell({ title: '고객 지원', back: '#/more' }, `
      <div class="card row" style="justify-content:space-between;"><span class="body-text">${icon('phone')} 고객센터 연락처</span><span class="muted">준비 중</span></div>
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

  onboarding() {
    return stackShell({ title: '이용 방법 안내', back: '#/more' }, `
      <div class="stack">
        <div class="card"><div class="h3">1. 접근성 설정</div><div class="muted">글자 크기와 쉬운 모드를 선택해요.</div></div>
        <div class="card"><div class="h3">2. 내 정보 입력</div><div class="muted">이름과 지역을 알려주세요.</div></div>
        <div class="card"><div class="h3">3. 보호자 안내</div><div class="muted">가족과 연결하면 더 안심할 수 있어요.</div></div>
      </div>
    `, { fixedBottom: `<button class="btn btn-primary" data-nav="#/home">시작하기</button>` });
  },
};

function recordCard(a) {
  return `<button class="card card-tap" data-nav="#/records/${a.id}">
    <div class="row" style="justify-content:space-between;">
      <span class="muted">${a.date}</span>
      <span class="badge ${riskBadgeClass(a.risk)}">${icon(riskIcon(a.risk))}${a.riskLabel}</span>
    </div>
    <div class="h3" style="margin:4px 0 2px;">${a.title}</div>
    <div class="muted" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${a.summary[0]}</div>
  </button>`;
}
