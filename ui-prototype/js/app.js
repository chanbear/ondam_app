// Router + state machine for the prototype shell. Nothing here is Flutter —
// this only drives which mock screen renders inside the phone frame.
const ALL_SCREENS = [...SENIOR_SCREENS, ...GUARDIAN_SCREENS];
const SCREEN_MAP = Object.fromEntries(ALL_SCREENS.map((s) => [s.id, s]));

const STATE = { app: null, screenId: null, elderId: "e1", variants: {}, history: [], frame: 390 };

const REVIEW_KEY = "ondam_proto_review_v1";
function loadReview() { try { return JSON.parse(localStorage.getItem(REVIEW_KEY)) || {}; } catch { return {}; } }
function saveReview(map) { localStorage.setItem(REVIEW_KEY, JSON.stringify(map)); }

function enterApp(app) {
  STATE.app = app; STATE.history = [];
  document.body.classList.add("in-app");
  buildNavigator();
  goTo(app + ".home", { replace: true });
}
function exitApp() {
  document.body.classList.remove("in-app");
}

function goTo(id, opts = {}) {
  const entry = SCREEN_MAP[id];
  if (!entry) return;
  if (STATE.screenId && !opts.replace) STATE.history.push(STATE.screenId);
  STATE.screenId = id;
  STATE.app = entry.app;
  render();
}
function goBack() {
  const prev = STATE.history.pop();
  if (prev) { STATE.screenId = prev; render(); }
}

function currentVariant(entry) { return STATE.variants[entry.id] || entry.states[0]; }

function render() {
  const entry = SCREEN_MAP[STATE.screenId];
  if (!entry) return;
  const variant = currentVariant(entry);
  const ctx = { elderId: STATE.elderId };

  const screenEl = document.getElementById("phoneScreen");
  screenEl.className = "phone-screen w-" + STATE.frame;
  screenEl.setAttribute("data-app", entry.app);
  const isEasy = entry.id === "senior.home" && variant === "Easy";
  screenEl.setAttribute("data-easy", isEasy ? "true" : "false");

  document.getElementById("phoneContent").innerHTML = entry.render(ctx, variant);

  const tabsWrap = document.getElementById("stateTabs");
  if (entry.states.length > 1) {
    tabsWrap.style.display = "flex";
    tabsWrap.innerHTML = entry.states.map((s) => `<button class="${s === variant ? "active" : ""}" data-nav-state="${s}">${s}</button>`).join("");
  } else {
    tabsWrap.style.display = "none"; tabsWrap.innerHTML = "";
  }

  document.getElementById("breadcrumb").innerHTML = `${entry.app === "senior" ? "Senior" : "Guardian"} / ${entry.cat} / <b>${entry.title}</b>`;
  renderDevPanel(entry, variant);
  highlightNav(entry.id);
}

function renderDevPanel(entry, variant) {
  const review = loadReview();
  const status = review[entry.id]?.status || "pending";
  const note = review[entry.id]?.note || "";
  const panel = document.getElementById("devpanel");
  panel.innerHTML = `
    <div class="eyebrow">${entry.app === "senior" ? "Senior" : "Guardian"} · ${entry.cat}</div>
    <h3>${entry.title}</h3>
    <div class="cat">요구사항 #${entry.spec} · 상태 ${entry.states.length}개</div>

    <div class="dp-block"><div class="dp-label">Purpose</div><div class="dp-text">${entry.purpose}</div></div>
    <div class="dp-block"><div class="dp-label">Reference</div><div class="dp-ref">${entry.ref}</div></div>
    <div class="dp-block"><div class="dp-label">Design Decision</div><div class="dp-text">${entry.decision}</div></div>

    <div class="dp-block">
      <div class="dp-label">Status</div>
      <div class="dp-status">
        ${[["pending", "검토 전"], ["revise", "수정 필요"], ["approved", "승인"]].map(([v, l]) => `
          <label><input type="radio" name="rev-status" value="${v}" ${status === v ? "checked" : ""} /> ${l}</label>
        `).join("")}
      </div>
    </div>
    <div class="dp-block">
      <div class="dp-label">메모</div>
      <textarea class="dp-note" id="revNote" placeholder="이 화면에 대한 메모...">${note}</textarea>
    </div>
    <div class="dp-progress" id="devProgress"></div>
  `;
  panel.querySelectorAll('input[name="rev-status"]').forEach((r) => r.addEventListener("change", (e) => {
    const rv = loadReview(); rv[entry.id] = { ...(rv[entry.id] || {}), status: e.target.value }; saveReview(rv);
    highlightNav(entry.id); renderProgress();
  }));
  panel.querySelector("#revNote").addEventListener("input", (e) => {
    const rv = loadReview(); rv[entry.id] = { ...(rv[entry.id] || {}), note: e.target.value }; saveReview(rv);
  });
  renderProgress();
}

function renderProgress() {
  const review = loadReview();
  const scoped = ALL_SCREENS.filter((s) => s.app === STATE.app);
  const counts = { approved: 0, revise: 0, pending: 0 };
  scoped.forEach((s) => { counts[review[s.id]?.status || "pending"]++; });
  const el = document.getElementById("devProgress");
  if (el) el.innerHTML = `<b>${counts.approved}</b>/${scoped.length} 승인 · ${counts.revise} 수정필요 · ${counts.pending} 검토전`;
}

function buildNavigator() {
  const scoped = ALL_SCREENS.filter((s) => s.app === STATE.app);
  const cats = [];
  scoped.forEach((s) => { if (!cats.includes(s.cat)) cats.push(s.cat); });
  const review = loadReview();
  let n = 1;
  const html = cats.map((cat) => {
    const items = scoped.filter((s) => s.cat === cat).map((s) => {
      const status = review[s.id]?.status || "pending";
      const num = n++;
      return `<button class="nav-item" data-goto="${s.id}" data-title="${s.title}"><span class="n">${String(num).padStart(2, "0")}</span>${s.title}<span class="status-dot ${status}"></span></button>`;
    }).join("");
    return `<div class="nav-cat"><div class="nav-cat-title">${cat}</div>${items}</div>`;
  }).join("");
  document.getElementById("navScreens").innerHTML = html;
  document.querySelectorAll(".app-switch button").forEach((b) => b.classList.toggle("active", b.dataset.appSwitch === STATE.app));
}

function highlightNav(id) {
  document.querySelectorAll(".nav-item").forEach((el) => el.classList.toggle("active", el.dataset.goto === id));
  const active = document.querySelector(`.nav-item[data-goto="${id}"]`);
  if (active) active.scrollIntoView({ block: "nearest" });
  document.querySelectorAll(".nav-item").forEach((el) => {
    const review = loadReview();
    const dot = el.querySelector(".status-dot");
    if (dot) { const st = review[el.dataset.goto]?.status || "pending"; dot.className = "status-dot " + st; }
  });
}

document.addEventListener("click", (e) => {
  const enterEl = e.target.closest("[data-enter]");
  if (enterEl) { enterApp(enterEl.dataset.enter); return; }

  const switchEl = e.target.closest("[data-app-switch]");
  if (switchEl) { enterApp(switchEl.dataset.appSwitch); return; }

  const exitEl = e.target.closest("[data-exit]");
  if (exitEl) { exitApp(); return; }

  const frameEl = e.target.closest("[data-frame]");
  if (frameEl) {
    STATE.frame = frameEl.dataset.frame;
    document.querySelectorAll(".frame-size button").forEach((b) => b.classList.toggle("active", b === frameEl));
    render(); return;
  }

  const gotoEl = e.target.closest("[data-goto]");
  if (gotoEl) { STATE.history.push(STATE.screenId); goTo(gotoEl.dataset.goto); return; }

  const backEl = e.target.closest("[data-back]");
  if (backEl) { goBack(); return; }

  const navEl = e.target.closest("[data-nav]");
  if (navEl) {
    const id = navEl.getAttribute("data-nav");
    if (navEl.hasAttribute("data-state")) STATE.variants[id] = navEl.getAttribute("data-state");
    goTo(id); return;
  }

  const stateTabEl = e.target.closest("[data-nav-state]");
  if (stateTabEl) { STATE.variants[STATE.screenId] = stateTabEl.getAttribute("data-nav-state"); render(); return; }

  const stateOnlyEl = e.target.closest("[data-state]:not([data-nav])");
  if (stateOnlyEl) { STATE.variants[STATE.screenId] = stateOnlyEl.getAttribute("data-state"); render(); return; }

  const elderEl = e.target.closest("[data-elder]");
  if (elderEl) { STATE.elderId = elderEl.getAttribute("data-elder"); render(); return; }
});

document.getElementById("navSearch").addEventListener("input", (e) => {
  const q = e.target.value.trim().toLowerCase();
  document.querySelectorAll(".nav-item").forEach((el) => {
    el.style.display = el.dataset.title.toLowerCase().includes(q) ? "flex" : "none";
  });
});

// landing stats line
document.getElementById("landingStats").textContent =
  `Senior ${SENIOR_SCREENS.length} screens · Guardian ${GUARDIAN_SCREENS.length} screens · ${ALL_SCREENS.length} total`;
