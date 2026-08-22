const ICONS = {
  brief:'<path d="M6 3h9l4 4v14H6z"/><path d="M15 3v4h4"/><path d="M9 12h7M9 15.5h7M9 8.5h3"/>',
  instr:'<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5z"/><path d="M4 5.5v15"/><path d="M8 8h8M8 11.5h8"/>',
  skill:'<path d="M13 2 4 13h6l-1 9 9-11h-6z"/>',
  conn:'<path d="M9 3v6M15 3v6M6 9h12l-1 4a5 5 0 0 1-10 0z"/><path d="M12 17v4"/>',
  hook:'<path d="M7 4v7a5 5 0 0 0 10 0V6"/><circle cx="7" cy="4" r="2"/><path d="M17 6a2 2 0 1 0 0-4 2 2 0 0 0 0 4z"/>',
  agent:'<circle cx="12" cy="8" r="3.2"/><path d="M5 20c0-4 3.2-6.5 7-6.5S19 16 19 20"/>',
  plugin:'<path d="M8 3v3M16 3v3M4 8h16v5a6 6 0 0 1-6 6h-4a6 6 0 0 1-6-6z"/><path d="M12 19v3"/>',
  set:'<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.15-1.5l2-1.5-2-3.5-2.3.9a7 7 0 0 0-2.6-1.5L13.5 2h-3l-.45 2.9a7 7 0 0 0-2.6 1.5l-2.3-.9-2 3.5 2 1.5A7 7 0 0 0 5 12c0 .5.05 1 .15 1.5l-2 1.5 2 3.5 2.3-.9c.75.65 1.63 1.16 2.6 1.5L10.5 22h3l.45-2.9a7 7 0 0 0 2.6-1.5l2.3.9 2-3.5-2-1.5c.1-.5.15-1 .15-1.5z"/>',
  guide:'<circle cx="12" cy="12" r="9"/><path d="m15 9-2 6-6 2 2-6z"/>',
  mon:'<rect x="3" y="4" width="18" height="12" rx="1.5"/><path d="M8 20h8M12 16v4"/><path d="m7 12 2.5-4L12 12l2-3 3 3"/>',
  apps:'<rect x="4" y="4" width="6" height="6" rx="1"/><rect x="14" y="4" width="6" height="6" rx="1"/><rect x="4" y="14" width="6" height="6" rx="1"/><rect x="14" y="14" width="6" height="6" rx="1"/>',
  harness:'<path d="M9 3h6M10 3v6l-5.5 9a2 2 0 0 0 1.7 3h11.6a2 2 0 0 0 1.7-3L14 9V3"/><path d="M8 15h8"/>',
  assist:'<path d="M12 3a9 9 0 0 0-9 9c0 1.6.4 3 1.2 4.3L3 21l4.9-1.1A9 9 0 1 0 12 3z"/><circle cx="8.7" cy="12" r=".9" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r=".9" fill="currentColor" stroke="none"/><circle cx="15.3" cy="12" r=".9" fill="currentColor" stroke="none"/>'
};

const SECTIONS = [
  {id:'brief', label:'브리핑', icon:'brief'},
  {id:'instr', label:'지침', icon:'instr'},
  {id:'skill', label:'스킬', icon:'skill'},
  {id:'conn', label:'커넥터', icon:'conn'},
  {id:'hook', label:'훅', icon:'hook'},
  {id:'agent', label:'에이전트', icon:'agent'},
  {id:'plugin', label:'플러그인', icon:'plugin'},
  {id:'set', label:'설정', icon:'set'},
  {id:'guide', label:'가이드', icon:'guide'},
  {id:'mon', label:'모니터', icon:'mon'},
  {id:'apps', label:'능력 앱', icon:'apps'},
  {id:'harness', label:'하네스', icon:'harness'},
  {id:'assist', label:'최근 활동', icon:'assist'},
];

let activeId = 'brief';
let latestState = null;
let modalStore = {};

function svg(key){ return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${ICONS[key]}</svg>`; }
function esc(s){ return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function fmtTime(epochSeconds){ return new Date(epochSeconds * 1000).toLocaleString('ko-KR'); }

function buildNav(){
  const nav = document.getElementById('nav');
  nav.innerHTML = '';
  SECTIONS.forEach(s => {
    const el = document.createElement('div');
    el.className = 'nav-item' + (s.id === activeId ? ' active' : '');
    el.dataset.id = s.id;
    el.innerHTML = svg(s.icon) + `<span>${s.label}</span>`;
    el.onclick = () => selectSection(s.id, s.label);
    nav.appendChild(el);
  });
}

function selectSection(id, label){
  if (activeId === 'mon' && id !== 'mon' && officeAnimHandle){
    cancelAnimationFrame(officeAnimHandle);
    officeAnimHandle = null;
  }
  activeId = id;
  document.querySelectorAll('.nav-item').forEach(n => n.classList.toggle('active', n.dataset.id === id));
  document.getElementById('pageTitle').textContent = label;
  if (latestState) renderActiveSection();
}

function openModal(key, index){
  const item = modalStore[key][index];
  document.getElementById('modalTitle').textContent = item.title;
  document.getElementById('modalBody').textContent = item.content || '(내용 없음)';
  document.getElementById('modalOverlay').classList.add('open');
}
function closeModal(){ document.getElementById('modalOverlay').classList.remove('open'); }
document.getElementById('modalOverlay').addEventListener('click', e => { if (e.target.id === 'modalOverlay') closeModal(); });
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });

function emptyState(text){ return `<div class="empty">${esc(text)}</div>`; }

function tileCard(opts){
  const clickAttr = opts.onclick ? ` onclick="${opts.onclick}"` : '';
  const cls = 'tile' + (opts.onclick ? ' clickable' : '');
  return `<div class="${cls}"${clickAttr}>
    <div class="tile-top">
      <div class="tile-icon">${opts.icon || ''}</div>
      ${opts.badgeHtml || ''}
    </div>
    <div class="tile-title">${esc(opts.title)}</div>
    ${opts.sub ? `<div class="tile-sub">${esc(opts.sub)}</div>` : ''}
    ${opts.extraHtml || ''}
  </div>`;
}

/* ---------- flutter analyze/test 공통: 상태 뱃지 · 실행 버튼 카드 · 트리거 ---------- */
function runStatusBadge(s, computeFail){
  if (!s.available) return '<span class="badge badge-off">flutter 미설치</span>';
  if (s.status === 'running') return '<span class="badge badge-warn">실행 중…</span>';
  if (s.status === 'error') return '<span class="badge badge-err">실행 실패</span>';
  if (s.status === 'done'){
    const fail = computeFail(s);
    if (fail) return `<span class="badge ${fail.cls}">${fail.text}</span>`;
    return '<span class="badge badge-on">통과</span>';
  }
  return '<span class="badge badge-off">아직 실행 안 함</span>';
}

function runStatusDetail(s){
  if (s.status !== 'done' && s.status !== 'error') return '';
  return `<div class="row-sub" style="margin-top:8px;">${esc(s.summary || '')}${s.ranAt ? ' · ' + esc(fmtTime(s.ranAt)) + (s.durationSec ? ` (${esc(s.durationSec)}s)` : '') : ''}</div>`;
}

function runStatusCard(s, badgeHtml, triggerName){
  const running = s.status === 'running';
  return `<div class="card">
    <div style="display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap;">
      ${badgeHtml}
      <button class="btn" ${(running || !s.available) ? 'disabled' : ''} onclick="${triggerName}()">${running ? '실행 중…' : '실행'}</button>
    </div>
    ${runStatusDetail(s)}
  </div>`;
}

async function triggerRun(url){
  try { await fetch(url, {method: 'POST'}); } catch (e){}
  poll();
}
function runBriefTest(){ return triggerRun('/api/brief/test'); }
function runHarnessAnalyze(){ return triggerRun('/api/harness/analyze'); }

function testStatusBadge(t){
  return runStatusBadge(t, s => s.failCount > 0 ? {cls: 'badge-err', text: `실패 ${s.failCount}건`} : null);
}

function renderBrief(d){
  const metrics = [
    ['브랜치', d.branch],
    ['미커밋 변경', d.uncommitted],
    ['스킬', d.skillCount],
    ['규칙 문서', d.ruleCount],
  ];
  const cards = metrics.map(([label, value]) => `
    <div class="card">
      <div class="metric-label">${esc(label)}</div>
      <div class="metric-value">${esc(value)}</div>
    </div>`).join('');

  const t = d.test;
  const perAppRows = t.perApp ? Object.entries(t.perApp).map(([app, r]) => `
    <div class="row">
      <div class="row-main"><div class="row-title">${esc(app)}</div></div>
      <div class="row-right">${r.note ? `<span class="badge badge-off">${esc(r.note)}</span>` : `<span class="badge ${r.fail > 0 ? 'badge-err' : 'badge-on'}">통과 ${esc(r.pass)} · 실패 ${esc(r.fail)}</span>`}</div>
    </div>`).join('') : '';

  return `
    <div class="desc">${esc(d.packageName)} 워크스페이스 · 앱 ${d.appCount}개</div>
    <div class="grid grid-4">${cards}</div>
    <div class="section-heading">마지막 커밋</div>
    <div class="card"><div class="row-title">${esc(d.lastCommit)}</div></div>
    <div class="section-heading">flutter test</div>
    ${runStatusCard(t, testStatusBadge(t), 'runBriefTest')}
    ${perAppRows ? `<div class="list" style="margin-top:12px;">${perAppRows}</div>` : ''}`;
}

function renderInstr(items){
  modalStore.instr = items;
  if (!items.length) return emptyState('지침 문서 없음');
  const tiles = items.map((it, i) => tileCard({
    icon: svg('instr'), title: it.title, sub: it.path, onclick: `openModal('instr', ${i})`,
  })).join('');
  return `<div class="tile-grid">${tiles}</div>`;
}

function renderSkill(items){
  if (!items.length) return emptyState('스킬 없음');
  const cards = items.map(it => `
    <div class="card">
      <div class="row-title">${esc(it.name)}</div>
      <div class="row-desc">${esc(it.description)}</div>
    </div>`).join('');
  return `<div class="grid grid-2">${cards}</div>`;
}

function connStatusBadge(status){
  if (status === 'missing_keys') return '<span class="badge badge-err">키 누락</span>';
  if (status === 'no_env_file') return '<span class="badge badge-off">.env 없음</span>';
  return '<span class="badge badge-on">연결됨</span>'; // 'configured' or 'n_a'
}

function renderConn(items){
  if (!items.length) return emptyState('감지된 커넥터 없음 (apps/*/pubspec.yaml 의존성 기준)');
  const tiles = items.map(it => tileCard({
    icon: svg('conn'), title: it.label, sub: `${it.app} · ${it.package}`,
    badgeHtml: connStatusBadge(it.status),
    extraHtml: (it.status === 'missing_keys' && it.missingKeys && it.missingKeys.length)
      ? `<div class="tile-sub" style="color:var(--coral); margin-top:6px;">누락: ${it.missingKeys.map(esc).join(', ')}</div>` : '',
  })).join('');
  return `<div class="tile-grid">${tiles}</div>`;
}

function renderHook(d){
  if (!d.configured || !d.items.length) return emptyState('설정된 훅 없음 (.claude/settings.json 의 hooks 가 비어있음)');
  const rows = d.items.map(it => `
    <div class="row">
      <div class="row-main">
        <div style="display:flex; align-items:center; gap:6px; flex-wrap:wrap;">
          <span class="badge badge-off">${esc(it.event)}</span>
          ${it.matcher ? `<span class="badge badge-off">${esc(it.matcher)}</span>` : ''}
          ${it.timeout != null ? `<span class="badge badge-off">${esc(it.timeout)}s</span>` : ''}
        </div>
        <div class="row-sub" style="margin-top:6px; font-family:'JetBrains Mono',monospace; font-size:12px; word-break:break-all;">${esc(it.command)}</div>
      </div>
    </div>`).join('');
  return `<div class="list">${rows}</div>`;
}

function renderAgent(items){
  if (!items.length) return emptyState('활성 워크트리 없음');
  const tiles = items.map(it => tileCard({
    icon: svg('agent'), title: it.name, sub: it.branch,
    badgeHtml: `<span class="badge ${it.status === 'working' ? 'badge-warn' : 'badge-on'}">${it.status === 'working' ? '작업 중' : '대기 중'}</span>`,
    extraHtml: `<div class="tile-sub" style="margin-top:6px;">수정 ${esc(fmtTime(it.mtime))}</div>`,
  })).join('');
  return `<div class="tile-grid">${tiles}</div>`;
}

/* ---------- 에이전트 오피스 (캔버스): ai_office_v4 디자인 그대로 이식, 데이터는 실제 워크트리 ---------- */
const OFFICE_W = 1000, OFFICE_H = 640;
const OFFICE_AISLE_X = 640;
const OFFICE_LOUNGE = {x1: 700, x2: 950, y1: 390, y2: 560};
const OFFICE_SHIRTS = ['#e0673f', '#4a90d9', '#5fae6f', '#c9843a', '#a35fc9', '#3ab5b0'];
const OFFICE_HAIR = ['#5b3a2a', '#2a2a2a', '#c98a3a', '#8a3a5a', '#3a5a8a', '#7a2a2a'];
const OFFICE_COLORS = {
  idle: '#7d8494', work: '#ffce54',
  text1: '#98A3B2', text2: '#5C6675', text0: '#E7ECF2',
  outline: '#14151c', skin: '#ffd9b0', skinShade: '#e8ac7c', eye: '#2a2420',
};

function officeShade(hex, amt){
  const n = parseInt(hex.slice(1), 16);
  const clamp = v => Math.max(0, Math.min(255, v));
  const r = clamp(((n >> 16) & 0xff) + amt), g = clamp(((n >> 8) & 0xff) + amt), b = clamp((n & 0xff) + amt);
  return `rgb(${r},${g},${b})`;
}
function officeRoundRect(ctx, x, y, w, h, r){
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}
function officeShortName(name){
  return name.length > 12 ? name.slice(0, 11) + '…' : name;
}

let officeAgents = {};
let officeAnimHandle = null;
let officeLastT = 0;
let officeProjectName = '';
const officeUsedSlots = new Set();

// 자리(slot) 위치는 에이전트 수와 무관하게 고정 — 워크트리가 추가/삭제돼도
// 기존 에이전트들은 자기 자리를 그대로 유지한다 (매번 다시 계산하면 인원수가 바뀔 때마다 다들 자리를 옮기게 된다).
const OFFICE_MAX_SEATS = 10;
function officeDeskSpots(n){
  const cols = [150, 380];
  const startY = 330, endY = 610, maxSpacing = 110;
  const rows = Math.max(1, Math.ceil(n / 2));
  const spacing = rows > 1 ? Math.min(maxSpacing, (endY - startY) / (rows - 1)) : 0;
  const spots = [];
  for (let i = 0; i < n; i++) spots.push({x: cols[i % 2], y: startY + Math.floor(i / 2) * spacing});
  return spots;
}
function officeRestSpots(n){
  const {x1, x2, y1, y2} = OFFICE_LOUNGE;
  if (n <= 1) return [{x: (x1 + x2) / 2, y: (y1 + y2) / 2}];
  const spots = [];
  for (let i = 0; i < n; i++){
    const f = i / (n - 1);
    spots.push({x: x1 + 24 + (x2 - x1 - 48) * f, y: y1 + 20 + (y2 - y1 - 40) * ((i % 2) ? 0.6 : 0.2)});
  }
  return spots;
}
const OFFICE_DESK_SPOTS = officeDeskSpots(OFFICE_MAX_SEATS);
const OFFICE_REST_SPOTS = officeRestSpots(OFFICE_MAX_SEATS);

function officeFreeSlot(){
  for (let s = 0; s < OFFICE_MAX_SEATS; s++) if (!officeUsedSlots.has(s)) return s;
  return -1;
}

function officeSyncAgents(items){
  const names = new Set();
  items.forEach(it => {
    names.add(it.name);
    const working = it.status === 'working';
    let emp = officeAgents[it.name];
    if (!emp){
      const slot = officeFreeSlot();
      if (slot === -1) return; // 자리가 다 찼으면 시각화에서만 생략 (실제 목록엔 영향 없음)
      officeUsedSlots.add(slot);
      emp = officeAgents[it.name] = {
        slot, real: it, x: 0, y: 0, facing: 1, path: [],
        status: working ? 'working' : 'resting', goingHome: false, knownWorking: working,
        shirt: OFFICE_SHIRTS[slot % OFFICE_SHIRTS.length], hair: OFFICE_HAIR[slot % OFFICE_HAIR.length],
        placed: false,
      };
    } else {
      emp.real = it;
      if (working !== emp.knownWorking && emp.status !== 'walking'){
        emp.status = 'walking'; emp.goingHome = !working; emp.knownWorking = working; emp.path = [];
      }
    }
  });
  Object.keys(officeAgents).forEach(name => {
    if (!names.has(name)){
      officeUsedSlots.delete(officeAgents[name].slot);
      delete officeAgents[name];
    }
  });
}

function drawOfficeSprite(ctx, cx, baseY, shirt, hair, facing, walking, walkStep, seated){
  cx = Math.round(cx); baseY = Math.round(baseY);
  const C = OFFICE_COLORS;
  const eyeDX = facing < 0 ? -1 : facing > 0 ? 1 : 0;

  ctx.fillStyle = 'rgba(0,0,0,0.32)';
  ctx.fillRect(cx - 11, baseY, 22, 3);

  if (!seated){
    const legL = walking && walkStep === 0 ? -1 : 0;
    const legR = walking && walkStep === 1 ? -1 : 0;
    ctx.fillStyle = '#14151c';
    ctx.fillRect(cx - 9, baseY - 20 + legL, 8, 18);
    ctx.fillRect(cx + 1, baseY - 20 + legR, 8, 18);
    ctx.fillStyle = '#3d4459';
    ctx.fillRect(cx - 8, baseY - 19 + legL, 6, 13);
    ctx.fillRect(cx + 2, baseY - 19 + legR, 6, 13);
    ctx.fillStyle = '#22242e';
    ctx.fillRect(cx - 8, baseY - 8 + legL, 6, 5);
    ctx.fillRect(cx + 2, baseY - 8 + legR, 6, 5);
    ctx.fillStyle = '#e6543f';
    ctx.fillRect(cx - 8, baseY - 4 + legL, 6, 3);
    ctx.fillRect(cx + 2, baseY - 4 + legR, 6, 3);
    ctx.fillStyle = 'rgba(255,255,255,0.4)';
    ctx.fillRect(cx - 8, baseY - 4 + legL, 6, 1);
    ctx.fillRect(cx + 2, baseY - 4 + legR, 6, 1);
  }

  const bodyH = seated ? 18 : 22;
  const bodyTop = seated ? baseY - 27 : baseY - 38;
  ctx.fillStyle = '#14151c';
  ctx.fillRect(cx - 13, bodyTop - 1, 26, bodyH + 2);
  ctx.fillStyle = shirt;
  ctx.fillRect(cx - 12, bodyTop, 24, bodyH);
  ctx.fillStyle = officeShade(shirt, -40);
  ctx.fillRect(cx - 12, bodyTop + bodyH - 6, 24, 6);
  ctx.fillStyle = officeShade(shirt, 35);
  ctx.fillRect(cx - 12, bodyTop, 24, 4);
  ctx.fillStyle = officeShade(shirt, -60);
  ctx.fillRect(cx - 1, bodyTop + 5, 2, bodyH - 9);
  ctx.fillStyle = 'rgba(255,255,255,0.5)';
  [0, 1, 2, 3].forEach(i => ctx.fillRect(cx - 1, bodyTop + 7 + i * 4, 2, 1));

  ctx.fillStyle = '#14151c';
  ctx.fillRect(cx - 12, bodyTop + bodyH - 8, 24, 2);

  const armSwing = seated ? Math.sin(Date.now() / 140) * 2 : walking ? (walkStep === 0 ? -3 : 3) : 0;
  ctx.fillStyle = '#14151c';
  ctx.fillRect(cx - 18, bodyTop + 2 + armSwing, 7, 16);
  ctx.fillRect(cx + 11, bodyTop + 2 - armSwing, 7, 16);
  ctx.fillStyle = officeShade(shirt, -15);
  ctx.fillRect(cx - 17, bodyTop + 3 + armSwing, 5, 11);
  ctx.fillRect(cx + 12, bodyTop + 3 - armSwing, 5, 11);
  ctx.fillStyle = C.skin;
  ctx.fillRect(cx - 17, bodyTop + 13 + armSwing, 5, 5);
  ctx.fillRect(cx + 12, bodyTop + 13 - armSwing, 5, 5);

  const headW = 20, headH = 19;
  const headY = bodyTop - headH + 3;
  ctx.fillStyle = '#14151c';
  ctx.fillRect(cx - headW / 2 - 1, headY - 1, headW + 2, headH + 2);
  ctx.fillStyle = C.skin;
  ctx.fillRect(cx - headW / 2, headY, headW, headH);
  ctx.fillStyle = C.skinShade;
  ctx.fillRect(cx - headW / 2, headY + headH - 5, headW, 4);
  ctx.fillStyle = 'rgba(255,255,255,0.35)';
  ctx.fillRect(cx - headW / 2, headY, headW, 2);

  ctx.fillStyle = '#14151c';
  ctx.fillRect(cx - headW / 2 - 2, headY - 7, headW + 4, 9);
  ctx.fillRect(cx - headW / 2 - 3, headY, 26, 3);
  ctx.fillStyle = hair;
  ctx.fillRect(cx - headW / 2 - 1, headY - 6, headW + 2, 7);
  ctx.fillRect(cx - headW / 2 - 2, headY + 1, 24, 2);
  ctx.fillStyle = officeShade(hair, 35);
  ctx.fillRect(cx - headW / 2 - 1, headY - 6, headW + 2, 2);
  ctx.fillStyle = officeShade(hair, -25);
  ctx.fillRect(cx - 2, headY - 6, 4, 7);

  ctx.fillStyle = officeShade(hair, -15);
  ctx.fillRect(cx - 6 + eyeDX, headY + 7, 4, 2);
  ctx.fillRect(cx + 2 + eyeDX, headY + 7, 4, 2);
  ctx.fillStyle = C.eye;
  ctx.fillRect(cx - 6 + eyeDX, headY + 10, 4, 4);
  ctx.fillRect(cx + 2 + eyeDX, headY + 10, 4, 4);
  ctx.fillStyle = '#fff';
  ctx.fillRect(cx - 6 + eyeDX, headY + 10, 2, 2);
  ctx.fillRect(cx + 2 + eyeDX, headY + 10, 2, 2);
  ctx.fillStyle = '#a35a4a';
  ctx.fillRect(cx - 2 + eyeDX, headY + 16, 4, 1);

  return {headTopY: headY - 14};
}

function drawOfficeBackground(ctx){
  ctx.fillStyle = '#c9773f';
  ctx.fillRect(0, 0, OFFICE_W, OFFICE_H);
  ctx.strokeStyle = 'rgba(90,50,20,0.12)';
  for (let y = 90; y < OFFICE_H; y += 12){ ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(OFFICE_W, y); ctx.stroke(); }

  ctx.fillStyle = '#f7f3ea';
  ctx.fillRect(0, 0, OFFICE_W, 88);

  ctx.fillStyle = '#5b8fc4';
  ctx.fillRect(18, 6, 60, 80); ctx.fillRect(84, 6, 60, 80);
  ctx.strokeStyle = 'rgba(255,255,255,0.35)'; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.moveTo(48, 6); ctx.lineTo(48, 86); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(114, 6); ctx.lineTo(114, 86); ctx.stroke();

  ctx.fillStyle = '#fff'; ctx.fillRect(190, 14, 110, 56);
  ctx.strokeStyle = '#cfcac0'; ctx.lineWidth = 3; ctx.strokeRect(190, 14, 110, 56);
  ctx.fillStyle = '#a9a49a'; ctx.fillRect(192, 66, 106, 4);

  ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(330, 42, 14, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = '#3d3a35'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(330, 42, 14, 0, Math.PI * 2); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(330, 42); ctx.lineTo(330, 33); ctx.moveTo(330, 42); ctx.lineTo(337, 42); ctx.stroke();

  ctx.fillStyle = '#c9915f'; ctx.fillRect(378, 58, 44, 30);
  ctx.fillStyle = '#4f8a3f';
  [[400, 45, 20], [386, 55, 16], [414, 55, 16]].forEach(([px, py, r]) => { ctx.beginPath(); ctx.arc(px, py, r, 0, Math.PI * 2); ctx.fill(); });

  // 상단 칸막이 유리 오피스 (빈 공간 — 특정 인원 배정 없음)
  ctx.fillStyle = '#14151c'; ctx.fillRect(428, 86, 254, 10);
  ctx.fillStyle = '#8a6a52'; ctx.fillRect(430, 88, 250, 6);
  ctx.fillStyle = '#14151c'; ctx.fillRect(428, 86, 10, 100);
  ctx.fillStyle = '#8a6a52'; ctx.fillRect(430, 88, 6, 96);
  ctx.fillStyle = '#14151c'; ctx.fillRect(680, 86, 10, 100);
  ctx.fillStyle = '#8a6a52'; ctx.fillRect(682, 88, 6, 96);
  ctx.fillStyle = 'rgba(255,255,255,0.15)';
  ctx.fillRect(430, 88, 6, 10); ctx.fillRect(682, 88, 6, 10);
  ctx.fillStyle = 'rgba(0,0,0,0.15)';
  officeRoundRect(ctx, 442, 138, 236, 10, 4); ctx.fill();
  ctx.fillStyle = 'rgba(210,220,230,0.55)';
  officeRoundRect(ctx, 440, 92, 240, 86, 4); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,0.5)'; ctx.lineWidth = 2; officeRoundRect(ctx, 440, 92, 240, 86, 4); ctx.stroke();

  ctx.fillStyle = '#14151c'; ctx.fillRect(698, 12, 204, 70);
  ctx.fillStyle = '#8a6a52'; ctx.fillRect(700, 14, 200, 66);
  for (let i = 0; i < 3; i++){
    const sx = 706 + i * 66;
    ctx.fillStyle = '#14151c'; ctx.fillRect(sx - 1, 19, 60, 56);
    ctx.fillStyle = '#6f5340'; ctx.fillRect(sx, 20, 58, 54);
    ctx.fillStyle = 'rgba(0,0,0,0.2)'; ctx.fillRect(sx, 42, 58, 2);
    for (let row = 0; row < 2; row++){ for (let c = 0; c < 5; c++){
      ctx.fillStyle = ['#c85a4a', '#5b8fc4', '#e0b84a', '#5f9e6f', '#9a6fc9'][(c + row) % 5];
      ctx.fillRect(sx + 4 + c * 10, 26 + row * 24, 7, 20);
      ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.fillRect(sx + 4 + c * 10, 26 + row * 24, 7, 2);
    }}
  }

  ctx.fillStyle = '#14151c'; ctx.fillRect(920, 12, 70, 46);
  ctx.fillStyle = '#222'; ctx.fillRect(922, 14, 66, 42);
  ctx.fillStyle = '#3a3f4b'; ctx.fillRect(928, 19, 54, 32);
  ctx.fillStyle = 'rgba(255,255,255,0.08)'; ctx.fillRect(928, 19, 54, 6);

  ctx.fillStyle = '#e9ecef'; ctx.fillRect(850, 90, 150, 220);
  ctx.strokeStyle = '#d6dade';
  for (let i = 850; i < 1000; i += 20){ ctx.beginPath(); ctx.moveTo(i, 90); ctx.lineTo(i, 310); ctx.stroke(); }
  for (let j = 90; j < 310; j += 20){ ctx.beginPath(); ctx.moveTo(850, j); ctx.lineTo(1000, j); ctx.stroke(); }

  ctx.fillStyle = '#14151c'; ctx.fillRect(866, 148, 48, 24);
  ctx.fillStyle = '#5b4a42'; ctx.fillRect(868, 150, 44, 20);
  ctx.fillStyle = officeShade('#5b4a42', 25); ctx.fillRect(868, 150, 44, 3);
  ctx.fillStyle = '#14151c'; ctx.fillRect(870, 110, 40, 46);
  ctx.fillStyle = '#3a3f4b'; ctx.fillRect(872, 112, 36, 42);
  ctx.fillStyle = '#7fb8d6'; ctx.fillRect(878, 118, 24, 14);
  ctx.strokeStyle = 'rgba(255,255,255,0.4)'; ctx.strokeRect(878, 118, 24, 14);
  ctx.fillStyle = '#e0b84a'; ctx.fillRect(890, 134, 4, 4);

  ctx.fillStyle = '#14151c'; ctx.fillRect(926, 98, 38, 74);
  ctx.fillStyle = '#dfe4e8'; ctx.fillRect(928, 100, 34, 70);
  ctx.fillStyle = '#8fd0ea'; ctx.beginPath(); ctx.ellipse(945, 108, 15, 10, 0, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,0.5)'; ctx.beginPath(); ctx.ellipse(945, 108, 15, 10, 0, 0, Math.PI * 2); ctx.stroke();
  ctx.fillStyle = '#7a95a8'; ctx.fillRect(936, 152, 18, 10);

  ctx.fillStyle = '#14151c'; ctx.fillRect(916, 203, 64, 49);
  ctx.fillStyle = '#6b6f78'; ctx.fillRect(918, 205, 60, 45);
  ctx.fillStyle = officeShade('#6b6f78', 25); ctx.fillRect(918, 205, 60, 4);
  ctx.fillStyle = '#2b2e35'; ctx.fillRect(924, 211, 48, 10);
  ctx.fillStyle = 'rgba(255,255,255,0.15)'; ctx.fillRect(924, 211, 48, 2);

  ctx.fillStyle = '#14151c'; ctx.fillRect(858, 263, 26, 30);
  ctx.fillStyle = '#8a8f97'; ctx.fillRect(860, 265, 22, 26);
  ctx.fillStyle = officeShade('#8a8f97', -25); ctx.fillRect(860, 285, 22, 6);

  ctx.fillStyle = '#14151c'; ctx.fillRect(38, 148, 194, 84);
  ctx.fillStyle = '#6b4a34'; ctx.fillRect(40, 150, 190, 80);
  ctx.fillStyle = '#8a5f43'; ctx.fillRect(40, 150, 190, 10);
  ctx.fillStyle = 'rgba(0,0,0,0.15)';
  for (let i = 0; i < 4; i++){ ctx.fillRect(56 + i * 44, 165, 26, 3); }
  [70, 135, 200].forEach(cx => {
    ctx.fillStyle = '#14151c'; ctx.beginPath(); ctx.ellipse(cx, 132, 16, 11, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#2f3a4a'; ctx.beginPath(); ctx.ellipse(cx, 132, 14, 9, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#14151c'; ctx.beginPath(); ctx.ellipse(cx, 248, 16, 11, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#2f3a4a'; ctx.beginPath(); ctx.ellipse(cx, 248, 14, 9, 0, 0, Math.PI * 2); ctx.fill();
  });

  // 라운지
  ctx.fillStyle = '#e6cfa3'; officeRoundRect(ctx, 700, 360, 290, 230, 16); ctx.fill();
  ctx.fillStyle = '#8e5fb0';
  officeRoundRect(ctx, 735, 375, 190, 42, 10); ctx.fill();
  officeRoundRect(ctx, 935, 430, 42, 150, 10); ctx.fill();
  officeRoundRect(ctx, 735, 565, 190, 42, 10); ctx.fill();
  ctx.fillStyle = 'rgba(190,220,235,0.55)';
  ctx.beginPath(); ctx.ellipse(850, 478, 56, 34, 0, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,0.6)'; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.ellipse(850, 478, 56, 34, 0, 0, Math.PI * 2); ctx.stroke();
  [[985, 375], [985, 565], [705, 375]].forEach(([px, py]) => {
    ctx.fillStyle = '#c9915f'; ctx.fillRect(px, py, 16, 14);
    ctx.fillStyle = '#4f8a3f'; ctx.beginPath(); ctx.arc(px + 8, py - 6, 12, 0, Math.PI * 2); ctx.fill();
  });
  ctx.strokeStyle = '#5b4a42'; ctx.lineWidth = 4;
  ctx.beginPath(); ctx.moveTo(660, 520); ctx.lineTo(660, 610); ctx.stroke();
  ctx.fillStyle = '#5b4a42';
  [[655, 528], [668, 536]].forEach(([px, py]) => { ctx.beginPath(); ctx.arc(px, py, 4, 0, Math.PI * 2); ctx.fill(); });
}

function drawOfficeDesk(ctx, x, y, occ, t){
  const working = occ && occ.status === 'working';
  ctx.fillStyle = 'rgba(0,0,0,0.15)';
  ctx.beginPath(); ctx.ellipse(x, y + 40, 52, 8, 0, 0, Math.PI * 2); ctx.fill();

  ctx.fillStyle = '#14151c'; ctx.fillRect(x - 54, y - 1, 108, 44);
  ctx.fillStyle = '#6b4a34'; ctx.fillRect(x - 52, y, 104, 42);
  ctx.fillStyle = '#8a5f43'; ctx.fillRect(x - 52, y, 104, 10);

  ctx.fillStyle = '#0c0d12'; ctx.fillRect(x - 32, y - 40, 48, 38);
  ctx.fillStyle = '#3a3f4b'; ctx.fillRect(x - 30, y - 38, 44, 36);
  ctx.fillStyle = working ? '#ffce54' : '#5c6270'; ctx.fillRect(x - 25, y - 33, 34, 24);
  if (working && Math.floor(t / 300) % 2 === 0){ ctx.fillStyle = '#fff'; ctx.fillRect(x - 20, y - 28, 6, 3); }

  ctx.fillStyle = '#4a4f5c'; ctx.fillRect(x - 28, y + 4, 36, 8);

  if (occ){
    ctx.fillStyle = '#0c0d12'; ctx.fillRect(x - 25, y - 53, 50, 15);
    ctx.fillStyle = '#1c1e27'; ctx.fillRect(x - 24, y - 52, 48, 14);
    ctx.fillStyle = '#ffce54'; ctx.font = 'bold 10px sans-serif'; ctx.textAlign = 'center';
    ctx.fillText(officeShortName(occ.real.name), x, y - 42);
  }
}

function officeAdvance(emp, target, dt){
  if (!emp.path.length){
    emp.path = [{x: OFFICE_AISLE_X, y: emp.y}, {x: OFFICE_AISLE_X, y: target.y}, {x: target.x, y: target.y}];
  }
  const wp = emp.path[0];
  const dx = wp.x - emp.x, dy = wp.y - emp.y, dist = Math.hypot(dx, dy);
  const speed = 0.15 * dt;
  if (dist < Math.max(speed, 2)){
    emp.x = wp.x; emp.y = wp.y; emp.path.shift();
  } else {
    if (Math.abs(dx) > 1) emp.facing = dx < 0 ? -1 : 1;
    emp.x += (dx / dist) * speed;
    emp.y += (dy / dist) * speed;
  }
  return emp.path.length === 0;
}

let officeBackgroundCanvas = null;
function getOfficeBackgroundCanvas(){
  // 배경(벽/바닥/가구)은 정적이라 한 번만 그려서 캐시해두고 매 프레임 이미지로 복사만 한다.
  if (!officeBackgroundCanvas){
    officeBackgroundCanvas = document.createElement('canvas');
    officeBackgroundCanvas.width = OFFICE_W;
    officeBackgroundCanvas.height = OFFICE_H;
    drawOfficeBackground(officeBackgroundCanvas.getContext('2d'));
  }
  return officeBackgroundCanvas;
}

function drawOffice(ctx, w, h, t){
  const dt = officeLastT ? Math.min(t - officeLastT, 50) : 16;
  officeLastT = t;
  ctx.clearRect(0, 0, w, h);
  ctx.drawImage(getOfficeBackgroundCanvas(), 0, 0);

  const items = Object.values(officeAgents);

  items.forEach(emp => drawOfficeDesk(ctx, OFFICE_DESK_SPOTS[emp.slot].x, OFFICE_DESK_SPOTS[emp.slot].y, emp, t));

  items.forEach(emp => {
    const deskSpot = OFFICE_DESK_SPOTS[emp.slot], restSpot = OFFICE_REST_SPOTS[emp.slot];
    const seatSpot = {x: deskSpot.x, y: deskSpot.y + 34};
    if (!emp.placed){
      const spot = emp.status === 'working' ? seatSpot : restSpot;
      emp.x = spot.x; emp.y = spot.y; emp.placed = true;
    }
    if (emp.status === 'walking'){
      const target = emp.goingHome ? restSpot : seatSpot;
      if (officeAdvance(emp, target, dt)){
        emp.status = emp.goingHome ? 'resting' : 'working';
        emp.goingHome = false; emp.path = [];
      }
    } else {
      emp.path = [];
    }
  });

  items.slice().sort((a, b) => a.y - b.y).forEach(emp => {
    const i = emp.slot;
    const walking = emp.status === 'walking';
    const seated = emp.status === 'working' && !walking;
    const bob = seated ? Math.sin(t / 900 + i) * 1
      : walking ? Math.abs(Math.sin(t / 110 + i)) * 3
      : Math.sin(t / 700 + i) * 1.2;
    const spriteY = emp.y - 96 + bob;
    const walkStep = Math.floor(t / 150) % 2;
    const {headTopY} = drawOfficeSprite(ctx, emp.x, spriteY, emp.shirt, emp.hair, emp.facing, walking, walkStep, seated);
    emp._hit = {x: emp.x - 24, y: headTopY, w: 48, h: spriteY - headTopY + 90};

    const cx = Math.round(emp.x);
    ctx.fillStyle = '#14151c'; ctx.fillRect(cx - 4, headTopY, 8, 8);
    ctx.fillStyle = emp.status === 'resting' ? OFFICE_COLORS.idle : OFFICE_COLORS.work;
    ctx.fillRect(cx - 3, headTopY + 1, 6, 6);
    ctx.fillStyle = 'rgba(255,255,255,0.7)'; ctx.fillRect(cx - 3, headTopY + 1, 3, 2);

    if (!seated){
      ctx.textAlign = 'center';
      ctx.font = "500 12px 'JetBrains Mono', monospace";
      ctx.fillStyle = OFFICE_COLORS.text0;
      ctx.fillText(officeShortName(emp.real.name), emp.x, spriteY + 108);
    }
  });
}

function officeShellHtml(){
  return `
    <div class="section-heading">에이전트 오피스</div>
    <div class="card office-card"><canvas id="officeCanvas" width="${OFFICE_W}" height="${OFFICE_H}"></canvas></div>
    <div class="office-legend">
      <span><i class="legend-dot" style="background:${OFFICE_COLORS.idle}"></i>휴게 중</span>
      <span><i class="legend-dot" style="background:${OFFICE_COLORS.work}"></i>업무/이동 중</span>
      <span class="office-hint">캐릭터를 클릭하면 상세 정보를 볼 수 있어요</span>
    </div>
    <div class="section-heading">변경된 파일</div>
    <div id="monFileList"></div>`;
}

function openOfficeAgentModal(name){
  const emp = officeAgents[name];
  if (!emp) return;
  const it = emp.real;
  const working = it.status === 'working';
  const workLine = working ? (it.focus ? `작업 중 · ${it.focus} · 변경 ${it.uncommitted}건` : `작업 중 · 변경 ${it.uncommitted}건`) : '대기 중';
  document.getElementById('modalTitle').textContent = it.name;
  document.getElementById('modalBody').textContent =
    `${it.branch}${it.app ? ' · ' + it.app + '팀' : ''}\n` +
    workLine +
    `\n마지막 커밋 ${it.lastCommit} · 수정 ${fmtTime(it.mtime)}`;
  document.getElementById('modalOverlay').classList.add('open');
}

function onOfficeClick(e){
  const canvas = e.currentTarget;
  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width, scaleY = canvas.height / rect.height;
  const mx = (e.clientX - rect.left) * scaleX, my = (e.clientY - rect.top) * scaleY;
  for (const name in officeAgents){
    const hb = officeAgents[name]._hit;
    if (hb && mx >= hb.x && mx <= hb.x + hb.w && my >= hb.y && my <= hb.y + hb.h){
      openOfficeAgentModal(name);
      return;
    }
  }
}

function officeLoop(t){
  const canvas = document.getElementById('officeCanvas');
  if (!canvas){ officeAnimHandle = null; return; }
  drawOffice(canvas.getContext('2d'), canvas.width, canvas.height, t);
  officeAnimHandle = requestAnimationFrame(officeLoop);
}

function renderMonFileList(mon){
  const el = document.getElementById('monFileList');
  if (!el) return;
  if (!mon.modified.length && !mon.untracked.length){
    el.innerHTML = emptyState('깨끗한 작업 트리 — 변경된 파일 없음');
    return;
  }
  const section = (title, files, badgeClass) => files.length ? `
    <div class="section-heading">${esc(title)} <span class="badge ${badgeClass}">${files.length}</span></div>
    <div class="list">${files.map(f => `<div class="row"><div class="row-main"><div class="row-title" style="font-family:'JetBrains Mono',monospace; font-size:12.5px;">${esc(f)}</div></div></div>`).join('')}</div>` : '';
  el.innerHTML = section('변경된 파일', mon.modified, 'badge-warn') + section('추적되지 않은 파일', mon.untracked, 'badge-err');
}

function renderMonSection(content, state){
  officeProjectName = (state.brief && state.brief.packageName) || '';
  if (!state.agent.length){
    if (officeAnimHandle){ cancelAnimationFrame(officeAnimHandle); officeAnimHandle = null; }
    officeAgents = {};
    content.innerHTML = `<div class="section-heading">에이전트 오피스</div>${emptyState('활성 워크트리 없음')}<div class="section-heading">변경된 파일</div><div id="monFileList"></div>`;
    renderMonFileList(state.mon);
    return;
  }
  if (!document.getElementById('officeCanvas')){
    content.innerHTML = officeShellHtml();
    document.getElementById('officeCanvas').addEventListener('click', onOfficeClick);
    if (officeAnimHandle) cancelAnimationFrame(officeAnimHandle);
    officeLastT = 0;
    officeAnimHandle = requestAnimationFrame(officeLoop);
  }
  officeSyncAgents(state.agent);
  renderMonFileList(state.mon);
}

function renderPlugin(items){
  if (!items.length) return emptyState('워크스페이스 패키지 없음');
  const tiles = items.map(it => tileCard({
    icon: svg('plugin'), title: it.name, sub: it.path,
    badgeHtml: `<span class="badge badge-off">deps ${esc(it.depCount)}</span>`,
  })).join('');
  return `<div class="tile-grid">${tiles}</div>`;
}

function renderSet(items){
  if (!items.length) return emptyState('permissions.allow 설정 없음');
  const chips = items.map(it => `<span class="chip">${esc(it)}</span>`).join('');
  return `<div class="chip-cloud">${chips}</div>`;
}

function renderGuide(items){
  modalStore.guide = items;
  if (!items.length) return emptyState('docs/ 문서 없음');
  const tiles = items.map((it, i) => tileCard({
    icon: svg('guide'), title: it.title, sub: it.path, onclick: `openModal('guide', ${i})`,
  })).join('');
  return `<div class="tile-grid">${tiles}</div>`;
}

function renderApps(items){
  const cards = items.map(it => `
    <div class="card">
      <div class="row-title">${esc(it.app)}</div>
      <div class="chip-cloud" style="margin-top:8px;">${it.features.length ? it.features.map(f => `<span class="chip">${esc(f)}</span>`).join('') : `<span class="tile-sub">features 없음</span>`}</div>
    </div>`).join('');
  return `<div class="grid grid-2">${cards}</div>`;
}

function harnessAnalyzeBadge(a){
  return runStatusBadge(a, s => {
    if (s.errorCount > 0) return {cls: 'badge-err', text: `오류 ${s.errorCount}건`};
    if (s.warningCount > 0) return {cls: 'badge-warn', text: `경고 ${s.warningCount}건`};
    return null;
  });
}

function renderHarness(h){
  const a = h.analyze;
  const sdkCards = ['flutter', 'dart'].map(k => `
    <div class="card">
      <div class="metric-label">${k}</div>
      <div class="row-title" style="font-family:'JetBrains Mono',monospace; font-size:12.5px;">${esc(h.sdk[k] || '설치 안 됨')}</div>
    </div>`).join('');
  const localMd = h.localMd
    ? `<div class="log-console">${esc(h.localMd)}</div>`
    : emptyState('CLAUDE.local.md 없음 — 이 머신의 개발 환경 설정이 아직 작성되지 않았습니다');

  return `
    <div class="section-heading">SDK</div>
    <div class="grid grid-2">${sdkCards}</div>
    <div class="section-heading">flutter analyze</div>
    ${runStatusCard(a, harnessAnalyzeBadge(a), 'runHarnessAnalyze')}
    <div class="section-heading">CLAUDE.local.md</div>
    ${localMd}`;
}

function renderAssist(items){
  if (!items.length) return emptyState('커밋 이력 없음');
  const lines = items.map(it => `<div class="log-line"><span class="t">${esc(it.hash)}</span>${esc(it.subject)} <span class="t">— ${esc(it.author)}, ${esc(it.relDate)}</span></div>`).join('');
  return `<div class="log-console">${lines}</div>`;
}

const RENDERERS = {
  brief: d => renderBrief(d.brief),
  instr: d => renderInstr(d.instr),
  skill: d => renderSkill(d.skill),
  conn: d => renderConn(d.conn),
  hook: d => renderHook(d.hook),
  agent: d => renderAgent(d.agent),
  plugin: d => renderPlugin(d.plugin),
  set: d => renderSet(d.set),
  guide: d => renderGuide(d.guide),
  apps: d => renderApps(d.apps),
  harness: d => renderHarness(d.harness),
  assist: d => renderAssist(d.assist),
};

function renderActiveSection(){
  const content = document.getElementById('content');
  if (activeId === 'mon'){ renderMonSection(content, latestState); return; }
  content.innerHTML = RENDERERS[activeId](latestState);
}

function setStatus(ok, message){
  const dot = document.getElementById('statusDot');
  const text = document.getElementById('statusText');
  dot.classList.toggle('stale', !ok);
  text.textContent = ok ? '실시간 반영 중' : (message || '연결 끊김 — 재시도 중');
}

async function poll(){
  try {
    const res = await fetch('/api/state', {cache: 'no-store'});
    if (res.status === 401){ setStatus(false, '인증 필요 — 토큰 링크로 다시 접속하세요'); return; }
    if (!res.ok) throw new Error('bad status');
    latestState = await res.json();
    setStatus(true);
    renderActiveSection();
  } catch (e) {
    setStatus(false);
  }
}

function tickClock(){
  document.getElementById('clock').textContent = new Date().toLocaleTimeString('ko-KR');
}

buildNav();
tickClock();
setInterval(tickClock, 1000);
poll();
setInterval(poll, 3000);
