// Reusable render fragments — every screen in screens.*.js composes these
// instead of writing bespoke markup, so 98 screens stay visually consistent.
const T = {
  msi: (name, extra = "") => `<span class="msi ${extra}">${name}</span>`,

  // flushLeft: back=false 화면(정보/기록처럼 최상위 탭)에서 뒤로가기 자리의
  // 빈 스페이서(width:var(--touch-min))까지 없애 타이틀을 화면 맨 왼쪽에 붙인다.
  // 2026-08-29 — 사용자 요청("정보/기록 타이틀을 화면 맨 왼쪽으로").
  topBar: (title, { back = true, right = "", flushLeft = false } = {}) => `
    <div class="top-bar">
      ${back ? `<button class="back" data-back>${T.msi("arrow_back")}</button>` : flushLeft ? "" : `<div style="width:${"var(--touch-min)"}"></div>`}
      <h1>${title}</h1>
      ${right}
    </div>`,

  card: (html, cls = "") => `<div class="card ${cls}">${html}</div>`,

  button: (label, { nav = "", variant = "", icon = "", large = false, attrs = "" } = {}) =>
    `<button class="btn ${variant} ${large ? "large" : ""}" ${nav ? `data-nav="${nav}"` : ""} ${attrs}>${icon ? T.msi(icon) : ""}${label}</button>`,

  iconBadge: (icon, tone = "primary", size = "") =>
    `<div class="icon-badge ${size} solid-${tone}">${T.msi(icon)}</div>`,
  iconBadgeTint: (icon, tone = "primary", size = "") =>
    `<div class="icon-badge ${size} tint-${tone}">${T.msi(icon)}</div>`,

  riskBadge: (level) => {
    const r = ondamRisk(level);
    return `<span class="risk-badge ${level}">${T.msi(r.icon)}${r.label}</span>`;
  },

  alertCard: (level, title, desc, action = "") => {
    const r = ondamRisk(level);
    return `<div class="alert-card ${level}">
      <div class="stripe"></div>
      <div class="icon-badge sm solid-${r.color}">${T.msi(r.icon)}</div>
      <div><div class="t">${title}</div><div class="d">${desc}</div>${action ? `<div class="a">${action}</div>` : ""}</div>
    </div>`;
  },

  statCard: (icon, tone, n, l) => `<div class="stat-card">${T.iconBadge(icon, tone, "sm")}<div class="n">${n}</div><div class="l">${l}</div></div>`,
  statGrid: (cards, two = false) => `<div class="stat-grid ${two ? "two" : ""}">${cards.join("")}</div>`,

  feeHero: (label, amount, deltaVal, comparedTo = "지난달보다") => {
    const good = deltaVal <= 0;
    return `<div class="fee-hero">
      <div class="lbl">${label}</div>
      <div class="amt">${won(amount)}</div>
      <div class="delta">${T.msi(good ? "trending_down" : "trending_up")} ${comparedTo} ${won(Math.abs(deltaVal))} ${good ? "적어요" : "많아요"}</div>
    </div>`;
  },

  // 2026-08-27 — Guardian 리디자인(사용자 제공 레퍼런스 이미지 기반): 5개 탭
  // 루트 화면(홈/받은 연락/기록/통계/더보기) 상단에 공통으로 쓰는 "온담 보호자"
  // 브랜드 헤더 + 어르신 전환 탭 + 인사말 + 통화 버튼 묶음. 하위 상세 화면은
  // 기존 T.topBar를 그대로 쓴다(레퍼런스에 없던 범위라 건드리지 않음).
  guardianTabHeader: (ctx, elder) => `
    <div class="g-header">
      <div class="g-header-brand">${T.msi("shield", "g-header-logo")}<span>온담 보호자</span></div>
      <div class="g-avatar">${elder.name[0]}</div>
    </div>
    <div style="padding:0 var(--sp-lg)">${T.chipRow(ctx.elderId)}</div>
    <div class="g-greeting-row">
      <div class="g-greeting">
        <div class="h1">${elder.name}, 안녕하세요</div>
        <span class="g-preview-badge"><span class="dot"></span>미리보기 데이터 · 10:44 업데이트됨</span>
      </div>
      <button class="g-call-btn" aria-label="전화하기">${T.msi("call")}</button>
    </div>`,

  barChart: (points, key) => {
    const vals = points.map((p) => p.v);
    const max = Math.max(...vals, 1);
    const w = 280, h = 100, pad = 8, gap = 12;
    const barW = (w - pad * 2 - gap * (points.length - 1)) / points.length;
    const bars = points.map((p, i) => {
      const bh = (p.v / max) * (h - pad * 2);
      const x = pad + i * (barW + gap);
      const y = h - pad - bh;
      return `<rect x="${x}" y="${y}" width="${barW}" height="${Math.max(bh, 2)}" rx="4" fill="var(--primary)" />`;
    }).join("");
    const labels = points.map((p) => `<span>${p[key]}</span>`).join("");
    return `<div class="chart-wrap">
      <svg viewBox="0 0 ${w} ${h}" width="100%" height="${h}">${bars}</svg>
      <div class="chart-legend">${labels}</div>
    </div>`;
  },

  // 2026-08-29 — Y축에 금액 표시 추가. 왼쪽에 축 라벨 공간을 두고(padLeft)
  // 최대/중간/최소 3개 눈금 + 옅은 점선 그리드라인을 그린다. 금액은 만원
  // 단위로 축약(예: 87,500 → 9만, 1,980,000 → 198만) — 축 폭이 좁아 원 단위
  // 전체 숫자는 들어가지 않는다.
  // 2026-08-29(2차) — 사용자 요청으로 "더 깔끔하게": 선 아래 옅은 그라디언트
  // 채우기 추가, 그리드라인을 점선+더 옅게, 점을 흰 테두리가 있는 2겹 원으로
  // (토스류 핀테크 차트에서 흔한 패턴), 위쪽 여백을 넉넉히 둬서 최고점이
  // 잘리는 느낌을 없앴다. chart-wrap도 은은한 그림자를 더해 흰 배경 페이지
  // 위에서도 카드 경계가 보이게 했다.
  lineChart: (points, key) => {
    const vals = points.map((p) => p.v);
    const max = Math.max(...vals), min = Math.min(...vals);
    const w = 280, h = 120, padTop = 18, padBottom = 12, padLeft = 34, padRight = 10;
    const step = (w - padLeft - padRight) / (points.length - 1);
    const y = (v) => h - padBottom - ((v - min) / (max - min || 1)) * (h - padTop - padBottom);
    const pts = points.map((p, i) => `${padLeft + i * step},${y(p.v)}`).join(" ");
    const areaPts = `${padLeft},${h - padBottom} ${pts} ${padLeft + (points.length - 1) * step},${h - padBottom}`;
    const dots = points.map((p, i) => `<circle cx="${padLeft + i * step}" cy="${y(p.v)}" r="5" fill="#fff" stroke="var(--primary)" stroke-width="2.5" />`).join("");
    const labels = points.map((p) => `<span>${p[key]}</span>`).join("");
    const fmtAxis = (v) => (v >= 10000 ? Math.round(v / 10000) + "만" : v.toLocaleString("ko-KR"));
    const ticks = [max, (max + min) / 2, min];
    const axis = ticks.map((v) => {
      const ty = y(v);
      return `<line x1="${padLeft}" y1="${ty}" x2="${w - padRight}" y2="${ty}" stroke="var(--divider)" stroke-width="1" stroke-dasharray="2 3" /><text x="${padLeft - 6}" y="${ty + 3}" text-anchor="end" font-size="8" fill="var(--text-secondary)">${fmtAxis(v)}</text>`;
    }).join("");
    const gradId = "lc" + Math.random().toString(36).slice(2, 8);
    // 2026-08-29 — 사용자 지적: viewBox(280x120)와 실제 렌더 크기(폭은
    // 카드에 맞춰 100%로 늘어나지만 높이는 고정 120px)의 가로세로 비율이
    // 달라, 기본 preserveAspectRatio(xMidYMid meet)가 균일 축소를 적용해
    // 그래프가 실제 카드 폭을 다 못 채우고 오른쪽에 빈 여백이 남았다 —
    // "Y축·X축 비율이 안 맞는" 원인. none으로 지정해 카드 폭/높이에 맞춰
    // 그대로 늘려 채운다.
    // 2026-08-29(2차) — 사용자 지적: 맨 아래 "3월" 라벨이 Y축(왼쪽 padLeft
    // 영역)보다 앞(왼쪽)에 나와 있었다 — .chart-legend는 SVG와 별개인 일반
    // flex row라 SVG 안의 실제 첫 데이터 포인트 x좌표(padLeft=34)를 몰랐고,
    // justify-content:space-between이 컨테이너 맨 왼쪽부터 라벨을 배치해
    // Y축 라벨 칸보다도 왼쪽에서 시작했던 것. SVG의 padLeft/padRight를
    // 컨테이너 폭 대비 %로 환산해 legend에 그대로 좌우 padding을 줘서
    // 첫/마지막 라벨이 실제 첫/마지막 데이터 포인트 바로 아래 오게 맞춘다.
    const legendPadLeft = (padLeft / w * 100).toFixed(2);
    const legendPadRight = (padRight / w * 100).toFixed(2);
    return `<div class="chart-wrap">
      <svg viewBox="0 0 ${w} ${h}" width="100%" height="${h}" preserveAspectRatio="none">
        <defs><linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="var(--primary)" stop-opacity="0.22" />
          <stop offset="100%" stop-color="var(--primary)" stop-opacity="0" />
        </linearGradient></defs>
        ${axis}
        <polygon points="${areaPts}" fill="url(#${gradId})" />
        <polyline points="${pts}" fill="none" stroke="var(--primary)" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round" />
        ${dots}
      </svg>
      <div class="chart-legend" style="padding-left:${legendPadLeft}%;padding-right:${legendPadRight}%">${labels}</div>
    </div>`;
  },

  emptyState: (icon, title, desc, actionLabel = "", actionNav = "") => `
    <div class="state-block">
      <span class="state-icon">${T.msi(icon)}</span><div class="t">${title}</div>${desc ? `<div class="d">${desc}</div>` : ""}
      ${actionLabel ? `<div style="width:100%;margin-top:14px">${T.button(actionLabel, { nav: actionNav })}</div>` : ""}
    </div>`,

  errorState: (desc, retryNav = "") => `
    <div class="state-block error">
      <span class="state-icon">${T.msi("error", "")}</span><div class="t">문제가 발생했어요</div><div class="d">${desc}</div>
      ${retryNav ? `<div style="width:100%;margin-top:14px">${T.button("다시 시도", { variant: "secondary", nav: retryNav })}</div>` : ""}
    </div>`,

  loadingState: (label = "불러오는 중이에요") => `
    <div class="state-block"><div class="spinner"></div><div class="t">${label}</div></div>`,

  // 2026-08-29(2차) — 사용자 요청으로 easy-mode-test 브랜치 구조(도움/홈/
  // 정보/더보기)를 되돌리고 원래 4탭(정보/홈/기록/더보기)으로 복귀. 긴급
  // 도움은 하단 네비 탭이 아니라 홈 화면의 3번째 기능 카드 아래 별도
  // 버튼으로 다시 옮겼다(S("home") 참고).
  bottomNavSenior: (active) => {
    const items = [
      { icon: "info", label: "정보", nav: "senior.info" },
      { icon: "home", label: "홈", nav: "senior.home" },
      { icon: "history", label: "기록", nav: "senior.records" },
      { icon: "more_horiz", label: "더보기", nav: "senior.more" },
    ];
    return `<div class="bottom-nav">${items.map((it) => `<button class="${it.nav === active ? "active" : ""}" data-nav="${it.nav}">${T.msi(it.icon)}<span>${it.label}</span></button>`).join("")}</div>`;
  },
  bottomNavGuardian: (active) => {
    const unread = ONDAM_DATA.notifications.filter((n) => !n.read).length;
    const items = [
      { icon: "home", label: "홈", nav: "guardian.home" },
      { icon: "mail", label: "받은 연락", nav: "guardian.notif-list", badge: unread },
      { icon: "history", label: "기록", nav: "guardian.records-all" },
      { icon: "bar_chart", label: "통계", nav: "guardian.stats-home" },
      { icon: "more_horiz", label: "더보기", nav: "guardian.more" },
    ];
    return `<div class="bottom-nav">${items.map((it) => `<button class="${it.nav === active ? "active" : ""}" data-nav="${it.nav}">${it.badge ? `<span class="nav-badge">${T.msi(it.icon)}<b>${it.badge}</b></span>` : T.msi(it.icon)}<span>${it.label}</span></button>`).join("")}</div>`;
  },
  // 2026-08-28 — 사용자 제공 참고 이미지 기반 Easy 홈 재설계: 도움 탭을 danger
  // 톤으로 튀게 해서 위치만으로도 눈에 띄게(색+아이콘+텍스트 3중 표현, 원칙 6).
  bottomNavEasy: (active) => {
    const items = [
      { icon: "sos", label: "도움", nav: "easy.emergency", danger: true },
      { icon: "info", label: "정보", nav: "easy.info" },
      { icon: "home", label: "홈", nav: "easy.home" },
      { icon: "history", label: "기록", nav: "easy.records" },
      { icon: "more_horiz", label: "더보기", nav: "easy.more" },
    ];
    return `<div class="bottom-nav">${items.map((it) => `<button class="${it.nav === active ? "active" : ""} ${it.danger ? "tab-danger" : ""}" data-nav="${it.nav}">${T.msi(it.icon)}<span>${it.label}</span></button>`).join("")}</div>`;
  },

  listRow: ({ leftBadge = "", title, sub, right = "", nav = "" }) => `
    <div class="list-row" ${nav ? `data-nav="${nav}" style="cursor:pointer"` : ""}>
      ${leftBadge}<div class="txt"><div class="tt">${title}</div><div class="ts">${sub}</div></div>${right}${nav ? T.msi("chevron_right", "chev") : ""}
    </div>`,

  notifCard: (n) => {
    const r = ondamRisk(n.kind);
    return `<div class="notif-card ${n.read ? "" : "unread"}" data-nav="guardian.notif-detail" data-id="${n.id}">
      ${T.iconBadge(r.icon, r.color, "sm")}
      <div style="flex:1"><div class="t">${n.title}</div><div class="d">${n.desc}</div><div class="ts">${n.ts}</div></div>
    </div>`;
  },

  chipRow: (activeId) => `<div class="chip-row">${ONDAM_DATA.elders.map((e) => `<button class="chip ${e.id === activeId ? "active" : ""}" data-elder="${e.id}">${T.msi("person")}${e.name}</button>`).join("")}</div>`,

  pinDots: (filled, total = 4, err = false) => `<div class="pin-dots">${Array.from({ length: total }).map((_, i) => `<div class="d ${i < filled ? (err ? "err" : "filled") : ""}"></div>`).join("")}</div>`,

  keypad: (nav, forgotNav = "") => `<div class="keypad">
    ${[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => `<button data-nav="${nav}">${n}</button>`).join("")}
    ${forgotNav ? `<button class="ghost" data-nav="${forgotNav}">잊으셨나요?</button>` : `<div></div>`}
    <button data-nav="${nav}">0</button>
    <button class="ghost" data-nav="${nav}">${T.msi("backspace")}</button>
  </div>`,

  dialog: (title, desc, actionsHtml) => `<div class="scrim center"><div class="dialog"><h3>${title}</h3><p>${desc}</p><div class="actions">${actionsHtml}</div></div></div>`,
  sheet: (html) => `<div class="scrim"><div class="sheet">${html}</div></div>`,

  qrBox: () => `<img class="qr-box" src="${ONDAM_QR_DATA_URI}" alt="보호자 연결용 QR 코드" />`,

  dots: (total, current) => `<div class="onb-dots">${Array.from({ length: total }).map((_, i) => `<span class="${i === current ? "active" : ""}"></span>`).join("")}</div>`,

  stepsRow: (labels, current) => `<div class="steps-row">${labels
    .map((l, i) => `${i > 0 ? `<div class="ln ${i <= current ? "done" : ""}"></div>` : ""}<div class="pt ${i <= current ? "done" : ""}">${i < current ? T.msi("check") : ""}</div>`)
    .join("")}</div>`,
};
