// Reusable render fragments — every screen in screens.*.js composes these
// instead of writing bespoke markup, so 98 screens stay visually consistent.
const T = {
  msi: (name, extra = "") => `<span class="msi ${extra}">${name}</span>`,

  topBar: (title, { back = true, right = "" } = {}) => `
    <div class="top-bar">
      ${back ? `<button class="back" data-back>${T.msi("arrow_back")}</button>` : `<div style="width:${"var(--touch-min)"}"></div>`}
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

  lineChart: (points, key) => {
    const vals = points.map((p) => p.v);
    const max = Math.max(...vals), min = Math.min(...vals);
    const w = 280, h = 110, pad = 10;
    const step = (w - pad * 2) / (points.length - 1);
    const y = (v) => h - pad - ((v - min) / (max - min || 1)) * (h - pad * 2);
    const pts = points.map((p, i) => `${pad + i * step},${y(p.v)}`).join(" ");
    const dots = points.map((p, i) => `<circle cx="${pad + i * step}" cy="${y(p.v)}" r="3" fill="var(--primary)" />`).join("");
    const labels = points.map((p) => `<span>${p[key]}</span>`).join("");
    return `<div class="chart-wrap">
      <svg viewBox="0 0 ${w} ${h}" width="100%" height="${h}">
        <polyline points="${pts}" fill="none" stroke="var(--primary)" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round" />
        ${dots}
      </svg>
      <div class="chart-legend">${labels}</div>
    </div>`;
  },

  emptyState: (icon, title, desc, actionLabel = "", actionNav = "") => `
    <div class="state-block">
      ${T.msi(icon)}<div class="t">${title}</div>${desc ? `<div class="d">${desc}</div>` : ""}
      ${actionLabel ? `<div style="width:100%;margin-top:14px">${T.button(actionLabel, { variant: "accent", nav: actionNav })}</div>` : ""}
    </div>`,

  errorState: (desc, retryNav = "") => `
    <div class="state-block">
      ${T.msi("error", "")}<div class="t">문제가 발생했어요</div><div class="d">${desc}</div>
      ${retryNav ? `<div style="width:100%;margin-top:14px">${T.button("다시 시도", { variant: "secondary", nav: retryNav })}</div>` : ""}
    </div>`,

  loadingState: (label = "불러오는 중이에요") => `
    <div class="state-block"><div class="spinner"></div><div class="t">${label}</div></div>`,

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
      { icon: "notifications", label: "알림", nav: "guardian.notif-list", badge: unread },
      { icon: "history", label: "기록", nav: "guardian.records-all" },
      { icon: "bar_chart", label: "통계", nav: "guardian.stats-home" },
      { icon: "more_horiz", label: "더보기", nav: "guardian.more" },
    ];
    return `<div class="bottom-nav">${items.map((it) => `<button class="${it.nav === active ? "active" : ""}" data-nav="${it.nav}">${it.badge ? `<span class="nav-badge">${T.msi(it.icon)}<b>${it.badge}</b></span>` : T.msi(it.icon)}<span>${it.label}</span></button>`).join("")}</div>`;
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

  qrBox: () => `<div class="qr-box"></div>`,

  stepsRow: (labels, current) => `<div class="steps-row">${labels
    .map((l, i) => `${i > 0 ? `<div class="ln ${i <= current ? "done" : ""}"></div>` : ""}<div class="pt ${i <= current ? "done" : ""}">${i < current ? T.msi("check") : ""}</div>`)
    .join("")}</div>`,
};
