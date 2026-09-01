// Router + state machine for the prototype shell. Nothing here is Flutter —
// this only drives which mock screen renders inside the phone frame.
const ALL_SCREENS = [...SENIOR_SCREENS, ...GUARDIAN_SCREENS, ...EASY_SCREENS];
const SCREEN_MAP = Object.fromEntries(ALL_SCREENS.map((s) => [s.id, s]));

// Easy는 ONDAM 2.0 사이드바에서 Senior/Guardian과 같은 층위의 별도 앱으로
// 보이지만, 실제로는 Senior의 큰 글씨/큰 터치영역 토큰([data-app="senior"]
// [data-easy="true"], css/tokens.css)을 그대로 물려받는다 — 화면을 렌더링할
// 땐 phoneScreen의 data-app을 "senior"로 세팅해 CSS가 적용되게 하고,
// STATE.app/entry.app은 "easy" 그대로 둬 네비게이터/진행률 등 도구 자체의
// 분류는 Easy로 유지한다.
function appLabel(app) { return app === "senior" ? "Senior" : app === "easy" ? "Easy" : "Guardian"; }
function cssAppFor(app) { return app === "easy" ? "senior" : app; }

const STATE = { app: null, screenId: null, elderId: "e1", variants: {}, history: [], frame: 390, overview: false };

// 2026-09-02 — 버그: "분석 중" 화면(문서/문자)이 "분석하기" 클릭 등 실사용
// 흐름으로 진입 가능한데 뒤로가기도, 자동 전환 타이머도 없어 영구히 멈췄다.
// 실제 앱처럼 분석이 끝나면 자동으로 결과 화면으로 넘어가게 한다.
const ANALYZING_NEXT = {
  "senior.doc-analyzing": "senior.doc-result",
  "senior.msg-analyzing": "senior.msg-result-real",
  "easy.doc-analyzing": "easy.doc-result",
  "easy.msg-analyzing": "easy.msg-result",
};
let analyzingTimer = null;

const REVIEW_KEY = "ondam_proto_review_v1";
function loadReview() { try { return JSON.parse(localStorage.getItem(REVIEW_KEY)) || {}; } catch { return {}; } }
function saveReview(map) { localStorage.setItem(REVIEW_KEY, JSON.stringify(map)); }

// 2026-08-28 — 사용자 요청: "초기에 로그인 화면부터 ... 쉬운 모드로 변경".
// Senior는 그대로 senior.home으로 진입하지만, Easy는 easy.home 전에
// easy.auth-login(로그인·소셜로그인·게스트 진입)을 거친다.
// 2026-09-01 — Guardian도 이제 곧장 guardian.home으로 진입하지 않고,
// 외부 레퍼런스 기반으로 새로 만든 guardian.connect(전화번호 연결) 화면을
// 먼저 거친다(screens.guardian.js "시작" 섹션 참고).
function enterApp(app) {
  STATE.app = app; STATE.history = [];
  document.body.classList.add("in-app");
  buildNavigator();
  const entryScreen = app === "easy" ? "easy.auth-login" : app === "guardian" ? "guardian.connect" : app + ".home";
  goTo(entryScreen, { replace: true });
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
  if (analyzingTimer) { clearTimeout(analyzingTimer); analyzingTimer = null; }
  const entry = SCREEN_MAP[STATE.screenId];
  if (!entry) return;
  const variant = currentVariant(entry);
  const ctx = { elderId: STATE.elderId };

  const screenEl = document.getElementById("phoneScreen");
  screenEl.className = "phone-screen w-" + STATE.frame;
  screenEl.setAttribute("data-app", cssAppFor(entry.app));
  screenEl.setAttribute("data-easy", entry.app === "easy" ? "true" : "false");

  document.getElementById("phoneContent").innerHTML = entry.render(ctx, variant);
  updateVoiceFab(entry);
  if (entry.app === "easy" && !AUTO_SPEAK_SKIP.has(entry.id)) {
    const text = AUTO_SPEAK[entry.id] ? AUTO_SPEAK[entry.id]() : readScreenAloud();
    if (text) speak(text);
  }

  const tabsWrap = document.getElementById("stateTabs");
  if (entry.states.length > 1) {
    tabsWrap.style.display = "flex";
    tabsWrap.innerHTML = entry.states.map((s) => `<button class="${s === variant ? "active" : ""}" data-nav-state="${s}">${s}</button>`).join("");
  } else {
    tabsWrap.style.display = "none"; tabsWrap.innerHTML = "";
  }

  document.getElementById("breadcrumb").innerHTML = `${appLabel(entry.app)} / ${entry.cat} / <b>${entry.title}</b>`;
  renderDevPanel(entry, variant);
  highlightNav(entry.id);
}

// 2026-08-28 — 사용자 요청: "말로 물어보기"를 홈 화면에서만 쓸 수 있게
// 두지 말고 그 외 어디서든 쓸 수 있게 별도 플로팅 버튼으로 뺀다. 홈은
// 이미 목록에 "말로 물어보기" 항목이 있어 중복이라 제외, voice 화면
// 자체(그 화면이 곧 음성 비서라 자기 자신을 띄우는 게 무의미)와 카메라
// (어두운 전체화면 촬영 UI와 겹침)·긴급도움 시트(도움 목록과 충돌)도 제외.
const VOICE_FAB_HIDDEN = new Set(["easy.home", "easy.voice", "easy.doc-camera", "easy.emergency"]);
// 2026-08-28 — 사용자 요청: "음성 지원/음성 비서를 영상으로 찍어서 발표
// 자료에 넣고 싶은데, 소리가 중요해서" — 지금까지 마이크 아이콘/문구뿐인
// 목업이던 "음성 안내"/"음성 비서"를 브라우저 내장 Web Speech API
// (SpeechSynthesis, 별도 서버·API Key 불필요, 실제 소리가 남)로 실제
// 작동하게 만든다. 사용자가 화면 녹화(시스템 소리 포함)만 직접 하면
// 실제 음성이 들어간 데모 영상이 된다.
function speak(text) {
  if (!("speechSynthesis" in window) || !text) return;
  window.speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text.replace(/\s+/g, " ").trim());
  u.lang = "ko-KR";
  u.rate = 0.95;
  window.speechSynthesis.speak(u);
}

// 화면 진입 시 자동으로 읽어줄 문구. 결과 화면(easy.doc-result/msg-result)은
// 위험도별로 내용이 달라 고정 문자열 대신, 이미 렌더된 DOM에서 헤드라인
// +AI 요약 문단을 그대로 읽어온다 — 화면에 보이는 문구와 항상 일치하게.
// 2026-08-28(5차) — easyResultBody() 구조 개편(.easy-rsl-label/.easy-rsl-summary
// 제거, .easy-rsl-headline/.easy-rsl-ai p로 대체)에 맞춰 셀렉터 갱신.
function readEasyResultAloud() {
  const headline = document.querySelector("#phoneContent .easy-rsl-headline")?.textContent || "";
  const aiSummary = document.querySelector("#phoneContent .easy-rsl-ai p")?.textContent || "";
  return `${headline}. ${aiSummary}`;
}
const AUTO_SPEAK = {
  "easy.voice": () => "듣고 있어요. 문서를 촬영해줘처럼 말씀해보세요.",
  "easy.doc-result": readEasyResultAloud,
  "easy.msg-result": readEasyResultAloud,
};

// 2026-08-30 — 사용자 요청: "음성 보조가 전체 화면에 적용되어 있지 않다"
// — 위 AUTO_SPEAK는 화면 3개뿐이었다. 화면마다 문구를 손으로 써넣는 대신,
// 이미 렌더된 DOM에서 [data-speak](수동 "다시 듣기" 버튼이 이미 들고 있는
// 큐레이션된 문구, 있으면 우선)나 제목(.h1/.easy-rsl-headline, 없으면
// top-bar의 bare h1)+첫 본문 문장을 그대로 읽어와 나머지 Easy 화면 전부를
// 커버한다.
function readScreenAloud() {
  const root = document.getElementById("phoneContent");
  const curated = root.querySelector("[data-speak]")?.getAttribute("data-speak");
  if (curated) return curated;
  const headline = root.querySelector(".h1, .easy-rsl-headline")?.textContent
    || root.querySelector(".top-bar h1")?.textContent || "";
  const body = root.querySelector(".body-sm, .body")?.textContent || "";
  return `${headline}. ${body}`.replace(/^\.\s*/, "").trim();
}
// 진입 시 자동으로 읽으면 오히려 방해되는 화면만 예외로 뺀다: 카메라
// 전체화면(easyVoiceFab도 같은 이유로 숨김), 몇 초 뒤 자동으로 다음
// 화면으로 넘어가는 로딩 화면, 긴급도움 시트(배경에 easy.home을 그대로
// 깔아서 .h1을 찾으면 시트 내용이 아니라 뒤에 숨은 홈 화면 문구를 잘못
// 읽어온다).
const AUTO_SPEAK_SKIP = new Set(["easy.doc-camera", "easy.doc-analyzing", "easy.msg-analyzing", "easy.emergency"]);

function updateVoiceFab(entry) {
  const fab = document.getElementById("easyVoiceFab");
  if (entry.app !== "easy" || VOICE_FAB_HIDDEN.has(entry.id)) {
    fab.style.display = "none";
    return;
  }
  fab.style.display = "flex";
  const hasBottomNav = !!document.querySelector("#phoneContent .bottom-nav");
  fab.classList.toggle("above-nav", hasBottomNav);
}

function renderDevPanel(entry, variant) {
  const review = loadReview();
  const status = review[entry.id]?.status || "pending";
  const note = review[entry.id]?.note || "";
  const panel = document.getElementById("devpanel");
  panel.innerHTML = `
    <div class="eyebrow">${appLabel(entry.app)} · ${entry.cat}</div>
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

function buildOverviewGrid() {
  const scoped = ALL_SCREENS.filter((s) => s.app === STATE.app);
  const cats = [];
  scoped.forEach((s) => { if (!cats.includes(s.cat)) cats.push(s.cat); });
  const ctx = { elderId: STATE.elderId };

  const rows = cats.map((cat) => {
    const items = scoped.filter((s) => s.cat === cat).map((entry) => {
      const variant = entry.states[0];
      let inner;
      try { inner = entry.render(ctx, variant); }
      catch (e) { inner = `<div style="padding:16px;font-size:11px;color:#900">렌더 오류: ${e.message}</div>`; }
      return `
        <div class="ov-item" data-ov-goto="${entry.id}">
          <div class="ov-frame">
            <div class="phone-screen w-390" data-app="${cssAppFor(entry.app)}" data-easy="${entry.app === "easy"}">
              <div class="phone-statusbar">
                <span>9:41</span>
                <span class="icons"><span class="msi" style="font-size:13px">wifi</span><span class="msi" style="font-size:13px">battery_full</span></span>
              </div>
              <div class="phone-content">${inner}</div>
            </div>
          </div>
          <div class="ov-label">${entry.title}</div>
        </div>`;
    }).join("");
    return `<div class="ov-cat">${cat}</div><div class="ov-row">${items}</div>`;
  }).join("");

  document.getElementById("overviewGrid").innerHTML =
    `<div class="ov-app-title">${appLabel(STATE.app)}<span class="ov-count">${scoped.length}개 화면</span></div>${rows}`;

  // 내용이 760px(기본 폰 높이)을 넘는 화면은 내부 스크롤로 잘리지 않도록
  // 프레임 자체를 실제 콘텐츠 높이만큼 늘린다 — scrollHeight는 transform:scale의
  // 영향을 받지 않는 레이아웃 값이라 그대로 잰다.
  const OV_SCALE = 150 / 390;
  document.querySelectorAll("#overviewGrid .ov-item").forEach((item) => {
    const screenEl = item.querySelector(".phone-screen");
    const contentEl = item.querySelector(".phone-content");
    const statusbarH = item.querySelector(".phone-statusbar").offsetHeight;
    const naturalH = statusbarH + contentEl.scrollHeight;
    if (naturalH > 760) {
      screenEl.style.height = naturalH + "px";
      contentEl.style.overflow = "visible";
      item.querySelector(".ov-frame").style.height = Math.round(naturalH * OV_SCALE) + "px";
    }
  });
}

function toggleOverview(on) {
  STATE.overview = on;
  document.getElementById("stage-body").classList.toggle("overview-mode", on);
  document.getElementById("overviewBtn").classList.toggle("active", on);
  if (on) buildOverviewGrid();
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
  const ovItemEl = e.target.closest(".ov-item");
  if (ovItemEl) { toggleOverview(false); goTo(ovItemEl.dataset.ovGoto); return; }

  const ovBtnEl = e.target.closest("#overviewBtn");
  if (ovBtnEl) { toggleOverview(!STATE.overview); return; }

  const enterEl = e.target.closest("[data-enter]");
  if (enterEl) { enterApp(enterEl.dataset.enter); return; }

  const switchEl = e.target.closest("[data-app-switch]");
  if (switchEl) { toggleOverview(false); enterApp(switchEl.dataset.appSwitch); return; }

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

  const speakEl = e.target.closest("[data-speak]");
  if (speakEl) { speak(speakEl.getAttribute("data-speak")); return; }

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

// 발표자료용 다운로드 — 이미지 캡처 라이브러리를 새로 추가하지 않고,
// 브라우저 기본 인쇄 대화상자("PDF로 저장")로 현재 화면만 내보낸다
// (css/shell.css의 @media print가 폰 목업만 남기고 나머지 UI를 숨김).
document.getElementById("downloadBtn").addEventListener("click", () => window.print());

document.getElementById("navSearch").addEventListener("input", (e) => {
  const q = e.target.value.trim().toLowerCase();
  document.querySelectorAll(".nav-item").forEach((el) => {
    el.style.display = el.dataset.title.toLowerCase().includes(q) ? "flex" : "none";
  });
});

// landing stats line
document.getElementById("landingStats").textContent =
  `Senior ${SENIOR_SCREENS.length} screens · Guardian ${GUARDIAN_SCREENS.length} screens · Easy ${EASY_SCREENS.length} screens · ${ALL_SCREENS.length} total`;
