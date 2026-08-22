/* ONDAM Senior — Phase 40 prototype. Mock state + hash router + event delegation.
   No network calls, no external deps. Load order: styles.css -> screens.js -> app.js */

const Icon = {
  doc: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2h9l5 5v15H6z"/><path d="M15 2v5h5"/><path d="M9 13h6M9 17h6"/></svg>`,
  message: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>`,
  home: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/></svg>`,
  info: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8h.01"/></svg>`,
  record: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16v16H4z"/><path d="M8 9h8M8 13h5"/></svg>`,
  more: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>`,
  mic: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 15a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v6a3 3 0 0 0 3 3z"/><path d="M19 11a7 7 0 0 1-14 0M12 18v3"/></svg>`,
  back: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 18l-6-6 6-6"/></svg>`,
  warning: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l10 18H2z"/><path d="M12 10v4M12 17h.01"/></svg>`,
  danger: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16h.01"/></svg>`,
  safe: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6L9 17l-5-5"/></svg>`,
  calendar: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/></svg>`,
  camera: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 8h3l2-3h6l2 3h3v12H4z"/><circle cx="12" cy="14" r="4"/></svg>`,
  flash: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M13 2 3 14h7l-1 8 11-14h-7z"/></svg>`,
  phone: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/></svg>`,
  close: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 6l12 12M18 6L6 18"/></svg>`,
  trash: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/></svg>`,
  chev: `<svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9l6 6 6-6"/></svg>`,
  qr: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3h-3zM19 19h2v2h-2z"/></svg>`,
  stats: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 20V10M12 20V4M20 20v-7"/></svg>`,
  location: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 21s7-6.6 7-11a7 7 0 1 0-14 0c0 4.4 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/></svg>`,
  support: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>`,
  lock: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>`,
};
function icon(name, cls) { return `<span class="icon ${cls||''}" aria-hidden="true">${Icon[name]||''}</span>`; }

function mkAnalysis(o) { return Object.assign({ confirmed: false, detailOpen: false }, o); }

const State = {
  loggedIn: false,
  easyMode: false,
  fontScale: 1, // 1 = normal, 1.15 = large, 1.3 = xlarge
  language: 'ko',
  phoneDraft: '',
  pinDraft: '',
  hasPin: false, // becomes true after first PIN set, drives login screen mode
  user: { name: '', age: '', region: '' },
  docPhotos: [],
  emergencySent: false,
  messages: [
    { id: 'sms-1', sender: '050-1234-5678', preview: '[Web발신] 고객님의 택배가 도착 예정입니다. 배송조회 http://bit.ly/3xk...', date: '08월 19일' },
    { id: 'sms-2', sender: '국민건강보험공단', preview: '8월분 건강보험료 안내드립니다. 자세한 내용은 앱에서...', date: '08월 20일' },
    { id: 'sms-3', sender: '02-123-4567', preview: '안녕하세요 OO경로당입니다. 이번주 목요일 점심 모임 안내...', date: '08월 18일' },
  ],
  analysis: {
    'doc-1': mkAnalysis({
      id: 'doc-1', kind: 'document', title: '국민건강보험료 안내문', date: '2026년 8월 20일',
      risk: 'warning', riskLabel: '확인이 필요해요',
      dueLabel: '납부 기한', due: '8월 25일',
      summary: ['이번 달 건강보험료 납부 안내문이에요.', '납부할 금액은 45,300원이에요.', '납부 기한은 8월 25일까지예요.', '기한을 넘기면 연체료가 붙을 수 있어요.'],
      todos: [
        { text: '8월 25일까지 보험료를 납부하세요.', checked: false },
        { text: '계좌이체 또는 편의점에서 납부할 수 있어요.', checked: false },
      ],
      confidence: 92,
      structured: [ { k: '보낸 곳', v: '국민건강보험공단' }, { k: '금액', v: '45,300원' }, { k: '납부 기한', v: '2026-08-25' } ],
      rawText: '[국민건강보험공단] 2026년 8월분 건강보험료 45,300원을 8월 25일까지 납부하여 주시기 바랍니다. 미납 시 연체료가 부과됩니다.',
    }),
    'msg-1': mkAnalysis({
      id: 'msg-1', kind: 'message', title: '택배 도착 사칭 문자', date: '2026년 8월 19일',
      risk: 'danger', riskLabel: '위험이 의심돼요',
      dueLabel: null, due: null,
      summary: ['이 문자는 위험할 수 있어요.', '모르는 번호에서 보낸 문자예요.', '택배 도착을 사칭한 문자예요.', '문자 속 주소를 누르면 안 돼요.'],
      todos: [
        { text: '문자 속 인터넷 주소를 누르지 마세요.', checked: false },
        { text: '의심되면 자녀나 보호자에게 확인을 요청하세요.', checked: false },
      ],
      confidence: 88,
      structured: [ { k: '보낸 번호', v: '050-1234-5678' }, { k: '위험 유형', v: '스미싱 의심' } ],
      rawText: '[Web발신] 고객님의 택배가 도착 예정입니다. 배송조회 http://bit.ly/3xk9zz',
      sourceMsgId: 'sms-1',
    }),
    'rec-1': mkAnalysis({
      id: 'rec-1', kind: 'document', title: '아파트 관리비 고지서', date: '2026년 8월 10일',
      risk: 'safe', riskLabel: '안전해요',
      dueLabel: '납부 기한', due: '8월 27일',
      summary: ['이번 달 아파트 관리비 고지서예요.', '금액은 132,400원이에요.', '납부 기한은 8월 27일까지예요.', '자동이체로 등록되어 있어요.'],
      todos: [ { text: '자동이체라 별도로 납부할 필요는 없어요.', checked: true } ],
      confidence: 95,
      structured: [ { k: '보낸 곳', v: 'OO아파트 관리사무소' }, { k: '금액', v: '132,400원' } ],
      rawText: '2026년 8월 관리비 132,400원, 납부기한 8월 27일, 자동이체 등록계좌로 출금 예정.',
      confirmed: true,
    }),
  },
  welfareCenters: [
    { name: '행복경로당', distance: '350m', phone: '02-111-2222', address: '동네 1길 12' },
    { name: '한마음경로당', distance: '720m', phone: '02-222-3333', address: '동네 3길 5' },
    { name: '느티나무경로당', distance: '1.1km', phone: '02-333-4444', address: '동네 5길 20' },
  ],
  guardians: [
    { name: '김보호 (딸)', status: 'accepted' },
    { name: '박보호 (아들)', status: 'pending' },
  ],
};

function fmtRecordsList() {
  return Object.values(State.analysis).sort((a,b) => a.date < b.date ? 1 : -1);
}

const Actions = {
  setPhoneDraft(v) { State.phoneDraft = v; },
  confirmPhone() { if (!State.phoneDraft) State.phoneDraft = '010-0000-0000'; render(); },
  resetPhone() { State.phoneDraft = ''; State.pinDraft = ''; render(); },
  setPinDigit(d) {
    if (State.pinDraft.length < 4) State.pinDraft += d;
    if (State.pinDraft.length === 4) {
      setTimeout(() => { State.hasPin = true; State.loggedIn = true; State.pinDraft = ''; navigate('#/home'); }, 220);
    }
    render();
  },
  pinBackspace() { State.pinDraft = State.pinDraft.slice(0, -1); render(); },
  logout() { State.loggedIn = false; State.pinDraft=''; navigate('#/login'); },
  deleteAccount() { State.loggedIn = false; State.hasPin=false; State.pinDraft=''; navigate('#/login'); },

  toggleEasy() { State.easyMode = !State.easyMode; document.documentElement.setAttribute('data-easy', State.easyMode); render(); },
  setFontScale(v) { State.fontScale = parseFloat(v); document.documentElement.style.setProperty('--user-scale', v); applyFontScale(); render(); },
  setLanguage(v) { State.language = v; render(); },

  bindProfile(field, value) { State.user[field] = value; },
  useCurrentLocation() { State.user.region = '서울특별시 은평구 OO동'; render(); },

  addPhoto() { State.docPhotos.push({ id: 'p'+Date.now() }); render(); },
  removePhoto(id) { State.docPhotos = State.docPhotos.filter(p => p.id !== id); render(); },

  startAnalysis(id, resultRoute) {
    navigate(resultRoute + '?loading=1');
    setTimeout(() => { navigate(resultRoute); }, 900);
  },

  toggleTodo(id, idx) { State.analysis[id].todos[idx].checked = !State.analysis[id].todos[idx].checked; render(); },
  toggleDetail(id) { State.analysis[id].detailOpen = !State.analysis[id].detailOpen; },
  confirmAnalysis(id) { State.analysis[id].confirmed = true; render(); },

  sendEmergency() { State.emergencySent = true; render(); setTimeout(() => { State.emergencySent = false; }, 3500); },

  connectGuardianRespond(idx, accept) {
    if (accept) State.guardians[idx].status = 'accepted';
    else State.guardians.splice(idx, 1);
    render();
  },
};

function applyFontScale() {
  document.documentElement.style.fontSize = (16 * State.fontScale) + 'px';
}

/* ---------- router ---------- */
function currentRoute() {
  const hash = location.hash || '#/login';
  const [path, query] = hash.split('?');
  const params = new URLSearchParams(query || '');
  return { path, params };
}
function navigate(hash) { location.hash = hash; }
function render() {
  const { path, params } = currentRoute();
  const root = document.getElementById('app');
  root.innerHTML = Screens.render(path, params);
  window.scrollTo(0, 0);
  const body = root.querySelector('.screen-body'); if (body) body.scrollTop = 0;
}

/* ---------- event delegation ---------- */
document.addEventListener('click', (e) => {
  const navEl = e.target.closest('[data-nav]');
  if (navEl) { navigate(navEl.getAttribute('data-nav')); return; }
  const actEl = e.target.closest('[data-action]');
  if (actEl) {
    const name = actEl.getAttribute('data-action');
    const args = (actEl.getAttribute('data-args') || '').split('|').filter(x => x !== '');
    if (Actions[name]) Actions[name](...args);
  }
});
document.addEventListener('input', (e) => {
  const bindEl = e.target.closest('[data-bind]');
  if (!bindEl) return;
  const [scope, field] = bindEl.getAttribute('data-bind').split('.');
  if (scope === 'profile') Actions.bindProfile(field, e.target.value);
  if (scope === 'phone') Actions.setPhoneDraft(e.target.value);
});
document.addEventListener('change', (e) => {
  if (e.target.matches('[data-font-scale]')) Actions.setFontScale(e.target.value);
  if (e.target.matches('[data-language]')) Actions.setLanguage(e.target.value);
});
window.addEventListener('hashchange', render);
window.addEventListener('DOMContentLoaded', () => {
  if (!location.hash) location.hash = '#/login';
  render();
});
