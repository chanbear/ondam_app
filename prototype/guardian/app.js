/* ONDAM Guardian — Phase 41 prototype. Mock state + hash router + event delegation.
   Same architecture as prototype/senior/app.js (kept independent — no shared JS file).
   No network calls, no external deps. Load order: styles.css -> screens.js -> app.js */

const Icon = {
  home: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/></svg>`,
  bell: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 8a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6z"/><path d="M10 21a2 2 0 0 0 4 0"/></svg>`,
  record: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16v16H4z"/><path d="M8 9h8M8 13h5"/></svg>`,
  stats: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 20V10M12 20V4M20 20v-7"/></svg>`,
  more: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>`,
  back: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 18l-6-6 6-6"/></svg>`,
  warning: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l10 18H2z"/><path d="M12 10v4M12 17h.01"/></svg>`,
  danger: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16h.01"/></svg>`,
  safe: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6L9 17l-5-5"/></svg>`,
  calendar: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/></svg>`,
  qr: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3h-3zM19 19h2v2h-2z"/></svg>`,
  person: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/></svg>`,
  support: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>`,
  lock: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>`,
  chev: `<svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9l6 6 6-6"/></svg>`,
  close: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 6l12 12M18 6L6 18"/></svg>`,
  refresh: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4v6h6M20 20v-6h-6"/><path d="M5.5 15a8 8 0 0 0 13.9 2.5M18.5 9a8 8 0 0 0-13.9-2.5"/></svg>`,
};
function icon(name, cls) { return `<span class="icon ${cls||''}" aria-hidden="true">${Icon[name]||''}</span>`; }

function mkAnalysis(o) { return Object.assign({ confirmed: false, detailOpen: false }, o); }

const State = {
  loggedIn: false,
  phoneDraft: '',
  pinDraft: '',
  hasPin: false, // becomes true after first PIN set, drives login screen mode

  connectedElders: [
    { id: 'e1', name: '김온담 (어머니)', status: 'safe', lastActivity: '오늘 오전 10:12 · 문서를 확인했어요' },
  ],
  elderBackup: null, // holds elders while the "no connection" demo state is shown
  pendingElders: [
    { id: 'e2', name: '이온담 (아버지)' },
  ],
  activeElderId: 'e1',

  notifications: [
    { id: 'n1', analysisId: 'g-doc-1', category: 'realtime', unread: true, risk: 'warning', title: '국민건강보험료 안내문', summary: '이번 달 건강보험료 납부 안내문이에요.', time: '10분 전', elder: '김온담 (어머니)' },
    { id: 'n2', analysisId: 'g-msg-1', category: 'realtime', unread: true, risk: 'danger', title: '택배 도착 사칭 문자', summary: '위험한 문자로 의심돼요.', time: '2시간 전', elder: '김온담 (어머니)' },
    { id: 'n3', analysisId: 'g-doc-2', category: 'risk', unread: false, risk: 'safe', title: '아파트 관리비 고지서', summary: '안전하게 확인된 문서예요.', time: '어제', elder: '김온담 (어머니)' },
    { id: 'n4', analysisId: 'g-msg-2', category: 'risk', unread: false, risk: 'danger', title: '대출 안내 스미싱 문자', summary: '위험 문자로 분류되어 안내했어요.', time: '3일 전', elder: '김온담 (어머니)' },
  ],

  analysis: {
    'g-doc-1': mkAnalysis({
      id: 'g-doc-1', kind: 'document', title: '국민건강보험료 안내문', date: '2026년 8월 20일', elder: '김온담 (어머니)',
      risk: 'warning', riskLabel: '확인이 필요해요',
      dueLabel: '납부 기한', due: '8월 25일',
      summary: ['이번 달 건강보험료 납부 안내문이에요.', '납부할 금액은 45,300원이에요.', '납부 기한은 8월 25일까지예요.', '기한을 넘기면 연체료가 붙을 수 있어요.'],
      todos: [
        { text: '납부 여부를 확인하세요.', checked: false },
        { text: '어르신께 납부 방법을 안내해 드리세요.', checked: false },
      ],
      confidence: 92,
      structured: [ { k: '보낸 곳', v: '국민건강보험공단' }, { k: '금액', v: '45,300원' }, { k: '납부 기한', v: '2026-08-25' } ],
      rawText: '[국민건강보험공단] 2026년 8월분 건강보험료 45,300원을 8월 25일까지 납부하여 주시기 바랍니다. 미납 시 연체료가 부과됩니다.',
    }),
    'g-msg-1': mkAnalysis({
      id: 'g-msg-1', kind: 'message', title: '택배 도착 사칭 문자', date: '2026년 8월 19일', elder: '김온담 (어머니)',
      risk: 'danger', riskLabel: '위험 가능성이 높아요',
      dueLabel: null, due: null,
      summary: ['위험할 수 있는 문자예요.', '모르는 번호에서 보낸 문자예요.', '택배 도착을 사칭한 문자예요.', '문자 속 인터넷 주소는 열지 않아야 해요.'],
      todos: [
        { text: '어르신께 문자 링크를 누르지 않도록 안내하세요.', checked: false },
        { text: '필요하면 해당 번호를 차단하세요.', checked: false },
      ],
      confidence: 88,
      structured: [ { k: '보낸 번호', v: '050-1234-5678' }, { k: '위험 유형', v: '스미싱 의심' } ],
      rawText: '[Web발신] 고객님의 택배가 도착 예정입니다. 배송조회 http://bit.ly/3xk9zz',
    }),
    'g-doc-2': mkAnalysis({
      id: 'g-doc-2', kind: 'document', title: '아파트 관리비 고지서', date: '2026년 8월 18일', elder: '김온담 (어머니)',
      risk: 'safe', riskLabel: '안전해요',
      dueLabel: '납부 기한', due: '8월 27일',
      summary: ['이번 달 아파트 관리비 고지서예요.', '금액은 132,400원이에요.', '납부 기한은 8월 27일까지예요.', '자동이체로 등록되어 있어요.'],
      todos: [ { text: '자동이체라 별도로 납부할 필요는 없어요.', checked: true } ],
      confidence: 95,
      structured: [ { k: '보낸 곳', v: 'OO아파트 관리사무소' }, { k: '금액', v: '132,400원' } ],
      rawText: '2026년 8월 관리비 132,400원, 납부기한 8월 27일, 자동이체 등록계좌로 출금 예정.',
      confirmed: true,
    }),
    'g-msg-2': mkAnalysis({
      id: 'g-msg-2', kind: 'message', title: '대출 안내 스미싱 문자', date: '2026년 8월 17일', elder: '김온담 (어머니)',
      risk: 'danger', riskLabel: '위험 가능성이 높아요',
      dueLabel: null, due: null,
      summary: ['저금리 대출을 안내하는 문자예요.', '공식 금융기관이 아닌 것으로 보여요.', '개인정보를 요구할 수 있어요.', '답장하거나 전화하지 않아야 해요.'],
      todos: [ { text: '어르신께 이미 위험 문자로 안내했어요.', checked: true } ],
      confidence: 90,
      structured: [ { k: '보낸 번호', v: '070-9999-1111' }, { k: '위험 유형', v: '대출 사기 의심' } ],
      rawText: '[저금리 특별대출] 누구나 즉시 승인, 상담 신청 070-9999-1111',
      confirmed: true,
    }),
  },

  feeStats: { total: 312400, avg: 104100, max: 132400, min: 45300, monthly: '6월 · 7월 · 8월 확인 건수: 1 / 2 / 3건', yearly: '2026년 확인 건수: 6건', analysisCount: 6, riskCount: 2 },
};

function activeElder() { return State.connectedElders.find(e => e.id === State.activeElderId) || State.connectedElders[0]; }
function fmtRecordsList() { return Object.values(State.analysis).sort((a,b) => a.date < b.date ? 1 : -1); }
function unreadCount() { return State.notifications.filter(n => n.unread).length; }

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
  requestPinReset() { State.hasPin = false; State.pinDraft = ''; navigate('#/login'); },
  logout() { State.loggedIn = false; State.pinDraft=''; navigate('#/login'); },
  deleteAccount() { State.loggedIn = false; State.hasPin=false; State.pinDraft=''; navigate('#/login'); },

  switchElder(id) { State.activeElderId = id; render(); },
  toggleElderDemo() {
    if (State.connectedElders.length) { State.elderBackup = State.connectedElders; State.connectedElders = []; }
    else { State.connectedElders = State.elderBackup || []; State.activeElderId = State.connectedElders[0] && State.connectedElders[0].id; }
    render();
  },
  disconnectElder(id) { State.connectedElders = State.connectedElders.filter(e => e.id !== id); render(); },
  respondPending(idx, accept) {
    const p = State.pendingElders[idx];
    if (accept) State.connectedElders.push({ id: p.id, name: p.name, status: 'safe', lastActivity: '방금 연결됐어요' });
    State.pendingElders.splice(idx, 1);
    render();
  },

  openAnalysis(id, backRoute) {
    navigate('#/detail/' + id + '?loading=1&back=' + encodeURIComponent(backRoute));
    setTimeout(() => { navigate('#/detail/' + id + '?back=' + encodeURIComponent(backRoute)); }, 900);
  },
  markRead(notifId) { const n = State.notifications.find(x => x.id === notifId); if (n) n.unread = false; },
  toggleTodo(id, idx) { State.analysis[id].todos[idx].checked = !State.analysis[id].todos[idx].checked; render(); },
  toggleDetail(id) { State.analysis[id].detailOpen = !State.analysis[id].detailOpen; },
  confirmAnalysis(id) {
    State.analysis[id].confirmed = true;
    const n = State.notifications.find(x => x.analysisId === id); if (n) n.unread = false;
    render();
  },
};

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
  const [scope] = bindEl.getAttribute('data-bind').split('.');
  if (scope === 'phone') Actions.setPhoneDraft(e.target.value);
});
window.addEventListener('hashchange', render);
window.addEventListener('DOMContentLoaded', () => {
  if (!location.hash) location.hash = '#/login';
  render();
});
