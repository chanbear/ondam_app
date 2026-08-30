// Guardian screen registry. 42 requested screen concepts covered by 31
// interactive screen ids (see SENIOR_SCREENS comment for the merge rationale
// — e.g. risk-level notification variants share one detail screen).
const GUARDIAN_SCREENS = [];
function G(id, cat, title, spec, purpose, ref, decision, states, render) {
  GUARDIAN_SCREENS.push({ id: "guardian." + id, app: "guardian", cat, title, spec, purpose, ref, decision, states: states || ["기본"], render });
}

// ---------- Authentication ----------
G("auth-login", "인증", "로그인", "57", "보호자 앱 진입 — 전화번호 로그인.",
  "Senior와 동일한 진입 패턴 공유(브랜드 일관성), 정보 밀도는 살짝 더 높게.",
  "\"보호자로 시작하기\" 문구로 역할을 명확히.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("shield", "primary", "lg")}
    <h1 class="h-display" style="margin-top:16px">온담 보호자</h1>
    <p class="body-sm" style="margin-bottom:32px">어르신의 안전을 한눈에</p>
    ${T.button("전화번호로 시작하기", { variant: "primary", nav: "guardian.auth-pin-setup", large: false })}
  </div>`);

G("auth-pin-setup", "인증", "PIN 설정", "58", "최초 PIN 생성.",
  "Senior와 동일 컴포넌트, 다만 카드가 더 조밀.",
  "재입력 확인 단계 동일 적용.", ["처음 입력", "다시 확인"], (ctx, state) => `
  ${T.topBar("PIN 설정")}
  <div class="scr" style="display:flex;flex-direction:column;min-height:calc(100% - 60px)">
    <p class="body" style="text-align:center">${state === "처음 입력" ? "PIN 번호 4자리를 설정해주세요" : "다시 한 번 입력해주세요"}</p>
    ${T.pinDots(state === "처음 입력" ? 3 : 4, 4, false)}
    ${T.keypad("guardian.onboard-welcome")}
  </div>`);

G("auth-pin-entry", "인증", "PIN 입력", "59", "재방문 인증.",
  "Senior와 동일.", "동일 컴포넌트 재사용.", ["입력 중", "오류"], (ctx, state) => `
  ${T.topBar("PIN 입력", { back: false })}
  <div class="scr" style="display:flex;flex-direction:column;min-height:calc(100% - 60px)">
    <p class="body" style="text-align:center">PIN 번호를 입력해주세요</p>
    ${T.pinDots(state === "오류" ? 4 : 3, 4, state === "오류")}
    ${state === "오류" ? `<p class="body-sm" style="text-align:center;color:var(--danger)">PIN이 올바르지 않아요</p>` : ""}
    ${T.keypad("guardian.home", "guardian.auth-login")}
  </div>`);

G("auth-error", "인증", "로그인 오류", "60", "인증 실패 안내.",
  "Senior와 동일 패턴.", "재시도 버튼 1개.", null, (ctx) => `
  <div class="scr center">
    ${T.msi("error", "")}
    <h2 class="h1" style="margin-top:12px">로그인에 실패했어요</h2>
    <p class="body-sm" style="margin-bottom:28px">전화번호 또는 PIN을 다시 확인해주세요</p>
    ${T.button("다시 시도하기", { variant: "primary", nav: "guardian.auth-login" })}
  </div>`);

// ---------- Onboarding ----------
G("onboard-welcome", "온보딩", "환영", "61", "보호자 앱 첫 실행 환영.",
  "Guardian은 온보딩을 짧게 — 핵심 가치만 1화면.",
  "\"무엇을 볼 수 있는지\"를 바로 보여줌(정보 지향).", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadgeTint("family_restroom", "primary", "lg")}
    <h1 class="h1" style="margin-top:16px">환영합니다</h1>
    <p class="body-sm" style="margin-bottom:32px">어르신의 안심 상태를<br>한눈에 확인하세요</p>
    ${T.button("시작하기", { variant: "primary", nav: "guardian.onboard-setup" })}
  </div>`);

G("onboard-setup", "온보딩", "기본 설정", "62", "알림 권한 등 최소 설정.",
  "권한은 필요한 시점에(just-in-time) 요청 원칙, 다만 알림은 핵심 기능이라 온보딩에서 1회 요청.",
  "알림 권한만 요청, 나머지는 설정에서.", null, (ctx) => `
  ${T.topBar("기본 설정")}
  <div class="scr">
    ${T.card(`<div class="row"><div style="flex:1"><div class="h-title">위험 알림 받기</div><div class="body-sm">위험 문자·문서 발견 시 즉시 알려드려요</div></div><button class="toggle on"></button></div>`)}
    <div style="margin-top:24px">${T.button("다음", { variant: "primary", nav: "guardian.onboard-done" })}</div>
  </div>`);

G("onboard-done", "온보딩", "온보딩 완료", "63", "온보딩 종료.",
  "완료 후 바로 어르신 연결로 유도.",
  "다음 행동(어르신 연결)을 명확한 CTA로.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "primary", "lg")}
    <h2 class="h1" style="margin-top:14px">준비가 끝났어요</h2>
    <p class="body-sm" style="margin-bottom:28px">이제 어르신을 연결해주세요</p>
    ${T.button("어르신 연결하기", { variant: "primary", nav: "guardian.elder-add" })}
  </div>`);

// ---------- Home ----------
// 2026-08-27 — 사용자 제공 레퍼런스 이미지 기반 전체 리디자인. elder-hero(진한
// 파란 히어로 카드) + 스탯 3개 그리드를 없애고, 브랜드 헤더 + 인사말 + "오늘
// 확인해주세요" 위험 알림 카드 + 최근 활동 목록으로 단순화. 어르신 전환 탭은
// 레퍼런스엔 없지만 다중 어르신 지원 유지 결정에 따라 인사말 위에 그대로 둠.
// QR 연결 흐름(elder-add/qr-scan 등)은 손대지 않음.
G("home", "홈", "홈 (어르신 없음 포함)", "64, 65", "\"지금 괜찮으신가\"에 최상단에서 답함(Guardian 원칙 1).",
  "사용자 제공 레퍼런스 이미지(온담 보호자 헤더 + 인사말 + 오늘 확인해주세요 카드 + 최근 활동) 그대로 반영.",
  "브랜드 헤더 + 어르신 탭 + 인사말 + 위험 알림 카드 + 최근 활동 순으로 정보 계층화 — 요약 스탯은 통계 탭으로 이동.", ["연결됨", "어르신 없음"], (ctx, state) => {
    if (state === "어르신 없음") {
      return `${T.topBar("홈", { back: false })}<div class="scr">${T.emptyState("family_restroom", "아직 연결된 어르신이 없습니다.", "", "어르신 연결하기", "guardian.elder-add")}</div>${T.bottomNavGuardian("guardian.home")}`;
    }
    const elder = ONDAM_DATA.elders.find((e) => e.id === ctx.elderId) || ONDAM_DATA.elders[0];
    return `
  <div class="scr flush" style="padding-bottom:var(--sp-xxl)">
    ${T.guardianTabHeader(ctx, elder)}
    <div style="padding:16px var(--sp-lg) 0">
      ${T.alertCard("dangerous", "오늘 확인해주세요", "개인정보를 요구하는 위험한 문자가 있어요.")}
      <div style="height:22px"></div>
      <div class="row between"><span class="section-title">최근 활동</span><button class="btn ghost" style="width:auto;padding:2px 4px;font-size:12.5px;color:var(--primary)" data-nav="guardian.records-all">전체보기</button></div>
      <div class="stack">
        ${T.listRow({ leftBadge: T.iconBadgeTint("sms", "primary", "sm"), title: "개인정보를 요구하는 위험한 문자예요", sub: "출처가 불분명한 링크가 포함되어 있어 누르지 않는 것이 안전해요 · 2일 전", right: T.riskBadge("dangerous"), nav: "guardian.records-detail" })}
        ${T.listRow({ leftBadge: T.iconBadgeTint("favorite", "primary", "sm"), title: "건강검진 예약 안내", sub: "가까운 건강기관에 예약하고 진단결과를 준비해주세요 · 3일 전", right: T.riskBadge("safe"), nav: "guardian.records-detail" })}
        ${T.listRow({ leftBadge: T.iconBadgeTint("local_hospital", "primary", "sm"), title: "병원 진료 예약 안내예요", sub: "내일 오전 10시 진료 예약이 있어 방문 준비하시면 돼요 · 4일 전", right: T.riskBadge("safe"), nav: "guardian.records-detail" })}
      </div>
    </div>
  </div>
  ${T.bottomNavGuardian("guardian.home")}`; });

G("elder-select", "홈", "어르신 선택", "66", "여러 어르신 중 전환.",
  "칩 형태로 즉시 전환, 목록 화면 이동 없이.",
  "현재 화면 유지한 채 데이터만 전환(재로딩 최소화).", null, (ctx) => `
  <div class="scr" style="position:relative;min-height:100%">
    ${T.sheet(`
      <h3 class="h-title">어르신 선택</h3>
      <div class="stack" style="margin-top:14px">
        ${ONDAM_DATA.elders.map((e) => T.listRow({ leftBadge: T.iconBadgeTint("person", "primary", "sm"), title: e.name, sub: `최근 활동 ${e.lastActive}`, right: T.riskBadge(e.risk) })).join("")}
      </div>
      <div style="margin-top:16px">${T.button("어르신 추가하기", { variant: "secondary", nav: "guardian.elder-add" })}</div>
    `)}
  </div>`);

G("elder-summary", "홈", "어르신 상태 요약", "67", "특정 어르신 상세 상태.",
  "핵심 지표를 상단에, 상세 기록은 하단에 점진적 노출.",
  "탭하면 records-detail로 드릴다운.", null, (ctx) => `
  ${T.topBar("아버님")}
  <div class="scr">
    ${T.alertCard("caution", "주의가 필요한 활동이 있어요", "최근 문자에서 위험 신호가 감지됐어요.")}
    <div style="height:16px"></div>
    ${T.statGrid([T.statCard("check_circle", "success", "12", "확인 완료"), T.statCard("error", "warning", "1", "미확인")], true)}
  </div>`);

// ---------- Elder Management ----------
G("elder-list", "어르신 관리", "어르신 목록", "68", "연결된 전체 어르신 관리.",
  "각 카드에 상태 요약을 함께 표시(빠른 상황 파악).",
  "카드 우측에 위험도 배지, 탭하면 요약으로.", null, (ctx) => `
  ${T.topBar("어르신 목록", { right: `<button class="right-action" data-nav="guardian.elder-add">${T.msi("add")}</button>` })}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    <div class="stack" style="padding-top:8px">
      ${ONDAM_DATA.elders.map((e) => T.listRow({ leftBadge: T.iconBadgeTint("person", "primary", "sm"), title: e.name, sub: `최근 활동 ${e.lastActive}`, right: T.riskBadge(e.risk), nav: "guardian.elder-summary" })).join("")}
    </div>
  </div>`);

G("elder-add", "어르신 관리", "어르신 추가", "69", "새 어르신 연결 시작.",
  "QR 스캔을 1차 방법으로 크게 제시.",
  "QR 외 코드 직접 입력은 보조 링크로.", null, (ctx) => `
  ${T.topBar("어르신 추가")}
  <div class="scr center">
    ${T.iconBadgeTint("qr_code_scanner", "primary", "lg")}
    <p class="body" style="margin:16px 0 28px">어르신 앱에서 발급한<br>QR 코드를 스캔해주세요</p>
    ${T.button("QR 스캔하기", { variant: "primary", nav: "guardian.qr-scan", icon: "qr_code_scanner" })}
  </div>`);

G("qr-scan", "어르신 관리", "QR 스캔", "70", "카메라로 QR 인식.",
  "카메라 화면은 최소 UI(Senior 카메라와 동일 패턴).",
  "스캔 프레임만 표시, 인식되면 자동 진행.", null, (ctx) => `
  <div class="scr flush" style="background:#111;min-height:100%;display:flex;flex-direction:column;color:#fff">
    <div class="top-bar" style="color:#fff"><button class="back" style="color:#fff" data-back>${T.msi("close")}</button><h1 style="color:#fff">QR 스캔</h1><div style="width:44px"></div></div>
    <div style="flex:1;display:flex;align-items:center;justify-content:center"><div style="width:200px;height:200px;border:3px solid #fff;border-radius:16px"></div></div>
    <div style="padding:20px">${T.button("스캔 완료 (시뮬레이션)", { variant: "primary", nav: "guardian.connect-request" })}</div>
  </div>`);

G("connect-request", "어르신 관리", "연결 요청", "71", "스캔 후 연결 요청 확인.",
  "상대방 이름을 다시 보여줘 실수 방지.",
  "요청 전 대상 확인 카드 1개.", null, (ctx) => `
  ${T.topBar("연결 요청")}
  <div class="scr center">
    ${T.iconBadgeTint("person", "primary", "lg")}
    <h2 class="h1" style="margin-top:14px">홍아버님과 연결할까요?</h2>
    <p class="body-sm" style="margin-bottom:24px">연결하면 위험 알림을 받을 수 있어요</p>
    ${T.button("연결 요청 보내기", { variant: "primary", nav: "guardian.connect-approve" })}
  </div>`);

G("connect-approve", "어르신 관리", "연결 승인 대기", "72", "상대방 승인 대기 상태.",
  "대기 상태를 명확히, 취소 가능함을 안내.",
  "스피너 대신 \"기다리고 있어요\" 카드로(과도한 로딩 인상 방지).", null, (ctx) => `
  <div class="scr center">
    ${T.loadingState("홍아버님의 승인을 기다리고 있어요")}
    <button class="btn ghost" data-nav="guardian.elder-list" style="margin-top:16px">나중에 확인하기</button>
  </div>`);

G("connect-done", "어르신 관리", "연결 완료", "73", "연결 성공 안내.",
  "완료 피드백은 짧고 명확하게.",
  "체크 아이콘 + 홈으로 이동 CTA.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "primary", "lg")}
    <h2 class="h1" style="margin-top:14px">연결됐어요</h2>
    <p class="body-sm" style="margin-bottom:24px">이제 아버님의 활동을 확인할 수 있어요</p>
    ${T.button("홈으로", { variant: "primary", nav: "guardian.home" })}
  </div>`);

G("connect-remove", "어르신 관리", "연결 해제 확인", "74", "연결 해제 — 되돌리기 어려운 행동.",
  "원칙 7 — 되돌리기 어려운 행동만 확인 다이얼로그.",
  "빨간 위험 버튼 + 명확한 결과 설명.", null, (ctx) => `
  <div class="scr" style="position:relative;min-height:100%">
    ${T.dialog("연결을 해제할까요?", "해제하면 아버님의 활동을 더 이상 볼 수 없어요.", `${T.button("취소", { variant: "secondary" })}${T.button("해제하기", { variant: "emergency" })}`)}
  </div>`);

// ---------- Records ----------
// 2026-08-27 — 레퍼런스 이미지의 "분석 기록" 탭엔 전체/위험/문서/문자 4개
// 필터가 있어 기존 3개(전체/문서/문자)에 "위험"을 추가.
G("records-all", "기록", "전체/위험/문서/문자 기록", "75, 76, 77", "탭 화면 — 필터로 위험/문서/문자 구분.",
  "Senior 기록 화면과 동일 컴포넌트 공유(일관성) + 레퍼런스 이미지의 4개 필터(전체/위험/문서/문자) 반영.",
  "필터 칩으로 목록 자체는 하나만 유지(별도 화면 대신).", ["전체", "위험", "문서", "문자"], (ctx, state) => {
    const elder = ONDAM_DATA.elders.find((e) => e.id === ctx.elderId) || ONDAM_DATA.elders[0];
    const docs = ONDAM_DATA.documents.map((d) => ({ ...d, kind: "문서" }));
    const msgs = ONDAM_DATA.messages.map((m) => ({ ...m, title: m.preview.slice(0, 16) + "…", kind: "문자" }));
    let items = [...docs, ...msgs];
    if (state === "문서") items = docs;
    else if (state === "문자") items = msgs;
    else if (state === "위험") items = items.filter((r) => r.risk === "dangerous");
    return `
  <div class="scr flush" style="padding-bottom:var(--sp-xxl)">
    ${T.guardianTabHeader(ctx, elder)}
    <div style="padding:0 var(--sp-lg)">
      <div class="section-title" style="margin:16px 0 8px">분석 기록</div>
      <div class="chip-row">${["전체", "위험", "문서", "문자"].map((l) => `<button class="chip ${l === state ? "active" : ""}" data-state="${l}">${l}</button>`).join("")}</div>
      <div class="stack" style="margin-top:12px">${items.length ? items.map((r) => T.listRow({ leftBadge: T.iconBadgeTint(r.kind === "문서" ? "description" : "sms", "primary", "sm"), title: r.title, sub: r.date, right: T.riskBadge(r.risk), nav: "guardian.records-detail" })).join("") : T.emptyState("history", "해당하는 기록이 없어요", "")}</div>
    </div>
  </div>
  ${T.bottomNavGuardian("guardian.records-all")}`; });

G("records-detail", "기록", "기록 상세 (위험/확인 완료)", "78, 79, 80", "기록 상세 + 확인 상태.",
  "Senior 상세 화면과 데이터 구조 공유, Guardian은 조치 버튼(알림 재전송 등) 추가.",
  "확인 여부 배지 + 원문 보기.", ["안전", "위험", "확인완료"], (ctx, state) => {
    const level = state === "위험" ? "dangerous" : state === "확인완료" ? "dangerous" : "safe";
    return `
  ${T.topBar("기록 상세")}
  <div class="scr">
    ${T.alertCard(level, level === "dangerous" ? "위험해요" : "안전한 문서예요", level === "dangerous" ? "금전이나 개인정보를 요구하고 있어요." : "특별히 위험한 내용은 없어요.")}
    <div style="height:16px"></div>
    ${T.card(`<div class="row between"><span class="body-sm">확인 상태</span>${state === "확인완료" ? `<span class="badge-dot">아버님이 확인함</span>` : `<span class="body-sm" style="color:var(--warning)">미확인</span>`}</div>`)}
    ${state !== "확인완료" ? `<div style="margin-top:20px">${T.button("확인 알림 다시 보내기", { variant: "secondary", nav: "guardian.records-detail", attrs: `data-state="확인완료"` })}</div>` : ""}
  </div>`; });

// ---------- Notifications (bottom nav label: 받은 연락, 2026-08-27 리네이밍) ----------
G("notif-list", "받은 연락", "받은 연락 목록", "81", "탭 화면 — 위험도순 정렬.",
  "시간순이 아니라 위험도순(Guardian 원칙 2).",
  "레퍼런스 이미지의 '받은 연락' 탭(원래 이름 알림) 반영 — 상단에 안 읽은 연락 수 요약 카드, 빈 상태는 기능 설명 문구.", ["목록", "빈 목록"], (ctx, state) => {
    const elder = ONDAM_DATA.elders.find((e) => e.id === ctx.elderId) || ONDAM_DATA.elders[0];
    const unread = state === "빈 목록" ? 0 : ONDAM_DATA.notifications.filter((n) => !n.read).length;
    return `
  <div class="scr flush" style="padding-bottom:var(--sp-xxl)">
    ${T.guardianTabHeader(ctx, elder)}
    <div style="padding:16px var(--sp-lg) 0">
      ${T.card(`<div class="row" style="gap:14px">${T.iconBadge("mail", unread ? "danger" : "success", "lg")}<div><div style="font-family:'JetBrains Mono',monospace;font-size:26px;font-weight:700">${unread}</div><div class="body-sm">읽지 않은 연락</div></div></div>`)}
      ${state === "빈 목록"
        ? `<div style="margin-top:14px">${T.card(`<p class="body-sm">아직 부모님에게 받은 연락이 없어요. 부모님이 온담에서 "보호자에게 알리기"를 누른 결과가 도착하면 여기 표시돼요.</p>`)}</div>`
        : `<div class="stack" style="margin-top:14px">${ONDAM_DATA.notifications.map((n) => T.notifCard(n)).join("")}</div>`}
    </div>
  </div>
  ${T.bottomNavGuardian("guardian.notif-list")}`; });

G("notif-detail", "받은 연락", "알림 상세 (위험/주의/중요 문서)", "82, 83, 84, 85", "알림 상세 → 기록 상세로 연결.",
  "알림과 기록이 같은 데이터임을 UI로 명확히 연결(Guardian 원칙 6).",
  "\"기록에서 보기\" 버튼으로 항상 기록 상세와 연결.", ["위험", "주의", "중요 문서"], (ctx, state) => {
    const map = { 위험: "dangerous", 주의: "caution", "중요 문서": "safe" };
    const level = map[state];
    return `
  ${T.topBar("알림 상세")}
  <div class="scr">
    ${T.alertCard(level, ondamRisk(level).label + (level !== "safe" ? "예요" : " 문서예요"), state === "중요 문서" ? "새 고지서가 등록됐어요." : "아버님께 온 문자에서 위험 신호가 감지됐어요.")}
    <div style="margin-top:20px">${T.button("기록에서 자세히 보기", { variant: "primary", nav: "guardian.records-detail" })}</div>
  </div>`; });

G("deeplink", "받은 연락", "Deep Link 도착 화면", "86", "푸시 알림 탭 → 앱 진입 직후 화면.",
  "Apple HIG — 알림 탭 시 관련 화면으로 바로 이동, 중간 화면 없이.",
  "홈을 거치지 않고 알림 상세로 즉시 진입, 상단에 \"알림에서 이동함\" 배지.", null, (ctx) => `
  <div class="scr flush" style="padding:0 var(--sp-lg) var(--sp-xxl)">
    <div style="padding:10px 0"><span class="caption">${T.msi("north_east")} 알림에서 이동했어요</span></div>
    ${T.alertCard("dangerous", "위험해요", "이 문자는 돈이나 개인정보를 요구하고 있어요.")}
    <div style="margin-top:20px">${T.button("기록에서 자세히 보기", { variant: "primary", nav: "guardian.records-detail" })}</div>
  </div>`);

// ---------- Statistics ----------
// 2026-08-27 — 레퍼런스 이미지의 "안심 통계" 탭 반영: 스탯 2개→4개(완료된
// 일정/남은 일정 추가), 최근 4주 활동 막대그래프, 보호자 안심 요약 체크리스트
// 추가. 요금 통계 진입 카드는 그대로 유지.
G("stats-home", "통계", "통계 홈 (빈 통계 포함)", "87, 91", "탭 화면 — 분석 건수/위험 건수/일정 요약 + 최근 활동 추이.",
  "실제 코드 statistics_tab_page.dart 구조(AppStatCard + 요금 통계 섹션) 기반, 레퍼런스 이미지의 4칸 스탯+막대그래프+안심 요약 카드로 확장.",
  "한눈에 보는 이용 현황 → 스탯 4칸 → 최근 4주 활동 → 보호자 안심 요약 → 요금 통계 진입 순.", ["기본", "빈 통계"], (ctx, state) => {
    const elder = ONDAM_DATA.elders.find((e) => e.id === ctx.elderId) || ONDAM_DATA.elders[0];
    return `
  <div class="scr flush" style="padding-bottom:var(--sp-xxl)">
    ${T.guardianTabHeader(ctx, elder)}
    <div style="padding:0 var(--sp-lg)">
      <div class="section-title" style="margin:16px 0 10px">한눈에 보는 이용 현황</div>
      ${state === "빈 통계" ? T.emptyState("bar_chart", "아직 통계로 보여드릴 데이터가 없습니다.", "") : `
      ${T.statGrid([T.statCard("insights", "primary", "5건", "이번 달 분석"), T.statCard("warning", "warning", "1건", "위험 문자"), T.statCard("event_available", "success", "1건", "완료된 일정"), T.statCard("calendar_today", "secondary", "2건", "남은 일정")], true)}
      <div style="height:18px"></div>
      <div class="section-title">최근 4주 활동</div>
      <div style="height:8px"></div>
      ${T.barChart(ONDAM_DATA.guardianWeeklyActivity, "w")}
      <div style="height:18px"></div>
      <div class="section-title">보호자 안심 요약</div>
      <div style="height:8px"></div>
      ${T.card(`
        <div class="g-summary-row">${T.msi("check_circle")}<span class="body-sm">확인이 필요한 위험 건 1건 있습니다.</span></div>
        <div class="g-summary-row">${T.msi("check_circle")}<span class="body-sm">앞으로 해야 할 일정이 7일 남았습니다.</span></div>
        <div class="g-summary-row">${T.msi("check_circle")}<span class="body-sm">부모님 안전 지표를 5일째 확인했습니다.</span></div>
      `)}
      <div style="height:20px"></div>
      <div class="section-title">요금 통계</div>
      <div class="card" data-nav="guardian.stats-fee"><div class="row between"><span class="h-title">자세히 보기</span>${T.msi("chevron_right")}</div></div>
      `}
    </div>
  </div>
  ${T.bottomNavGuardian("guardian.stats-home")}`; });

G("stats-fee", "통계", "요금 통계 (월별/연별)", "88, 89, 90", "어르신 이름 → 이번 달 요금 → 추이.",
  "사용자 지정 구조: 어르신 이름 → 이번 달 요금 → 월별 추이 → 연간 추이.",
  "정보 밀도를 Senior보다 높게 — 표 형태 요약 병행.", ["월별", "연별"], (ctx, state) => {
    const isMonthly = state === "월별";
    const data = isMonthly ? ONDAM_DATA.feeStats.monthly : ONDAM_DATA.feeStats.yearly;
    return `
  ${T.topBar("요금 통계")}
  <div class="scr">
    <div class="row"><span class="caption">아버님</span></div>
    <div class="chip-row" style="margin-top:8px">${["월별", "연별"].map((l) => `<button class="chip ${l === state ? "active" : ""}" data-state="${l}">${l}</button>`).join("")}</div>
    <div style="height:14px"></div>
    ${T.feeHero(isMonthly ? "8월 요금" : "2026년 요금", isMonthly ? 87500 : 1980000, isMonthly ? -12500 : -300000, isMonthly ? "지난달보다" : "작년보다")}
    <div style="height:16px"></div>
    ${T.lineChart(data, isMonthly ? "m" : "y")}
    <div style="height:20px"></div>
    ${T.statGrid([T.statCard("payments", "primary", won(ONDAM_DATA.feeStats.total), "총 금액"), T.statCard("insights", "secondary", won(ONDAM_DATA.feeStats.avg), "평균"), T.statCard("north", "warning", won(ONDAM_DATA.feeStats.max), "최고"), T.statCard("south", "success", won(ONDAM_DATA.feeStats.min), "최저")])}
  </div>`; });

G("stats-by-elder", "통계", "어르신별 통계", "92", "여러 어르신 요금 비교.",
  "비교는 막대(카테고리 비교=막대 원칙) 대신 리스트+금액 정렬로 단순화.",
  "많아야 2~3명이라 차트보다 리스트가 더 명확.", null, (ctx) => `
  ${T.topBar("어르신별 통계")}
  <div class="scr">
    <div class="stack">
      ${ONDAM_DATA.elders.map((e) => T.listRow({ leftBadge: T.iconBadgeTint("person", "primary", "sm"), title: e.name, sub: "이번 달 요금", right: `<span class="amt">${won(e.id === "e1" ? 87500 : 38200)}</span>`, nav: "guardian.stats-fee" })).join("")}
    </div>
  </div>`);

G("stats-detail", "통계", "통계 상세", "93", "개별 고지서 원본 정보(현재 코드 그대로).",
  "고지서 통계 항목 미결정 상태를 그대로 반영 — 원본 나열.",
  "structuredFields 나열 UI 유지.", null, (ctx) => `
  ${T.topBar("고지서 정보")}
  <div class="scr">
    ${T.card(`<div class="body-sm">2026.08.25</div><div style="height:10px"></div><div class="row between"><span class="body-sm">항목명</span><span class="body">전기요금</span></div><div style="height:8px"></div><div class="row between"><span class="body-sm">금액</span><span class="body">87,500원</span></div>`)}
  </div>`);

// ---------- More ----------
// 2026-08-27 — id를 settings→more로 변경. bottomNavGuardian의 "더보기" 탭은
// 원래부터 nav:"guardian.more"를 가리켰는데 실제 화면 id는 "guardian.settings"
// 였어서 더보기 탭을 눌러도 아무 반응이 없던 버그였음(SCREEN_MAP에 guardian.more가
// 없어 goTo()가 조용히 무시). id를 nav 타겟과 맞춰 고침 + 레퍼런스 이미지처럼
// 항목마다 아이콘 배지를 추가.
G("more", "더보기", "더보기", "94", "일반 설정 목록.",
  "레퍼런스 이미지의 더보기 탭 — 브랜드 헤더 + 아이콘 배지가 있는 리스트.",
  "Senior 설정과 동일한 정보구조, 항목만 다름(어르신 관리 추가) — 항목마다 아이콘 배지로 시각적 밀도 보완.", null, (ctx) => {
    const elder = ONDAM_DATA.elders.find((e) => e.id === ctx.elderId) || ONDAM_DATA.elders[0];
    return `
  <div class="scr flush" style="padding-bottom:var(--sp-xxl)">
    ${T.guardianTabHeader(ctx, elder)}
    <div style="padding:16px var(--sp-lg) 0">
      <div class="stack">
        ${T.listRow({ leftBadge: T.iconBadgeTint("notifications", "primary", "sm"), title: "알림 설정", sub: "위험 알림, 다이제스트", nav: "guardian.notif-settings" })}
        ${T.listRow({ leftBadge: T.iconBadgeTint("accessibility_new", "primary", "sm"), title: "접근성", sub: "글자 크기", nav: "guardian.accessibility" })}
        ${T.listRow({ leftBadge: T.iconBadgeTint("person", "primary", "sm"), title: "계정", sub: "전화번호, 비밀번호", nav: "guardian.account" })}
        ${T.listRow({ leftBadge: T.iconBadgeTint("family_restroom", "primary", "sm"), title: "연결된 어르신 관리", sub: "2명", nav: "guardian.manage-elders" })}
      </div>
    </div>
  </div>
  ${T.bottomNavGuardian("guardian.more")}`; });

G("notif-settings", "설정", "알림 설정", "95", "알림 종류별 on/off.",
  "위험 알림은 즉시 발송(끌 수 없음), 그 외는 다이제스트 선택 가능(원칙 — 알림 심각도 표시 3단, 발송은 2단).",
  "위험 알림 = 항상 켜짐, 나머지만 토글.", null, (ctx) => `
  ${T.topBar("알림 설정")}
  <div class="scr">
    <div class="stack md">
      ${T.card(`<div class="row between"><span class="h-title">위험 알림</span><span class="caption">항상 켜짐</span></div>`)}
      ${T.card(`<div class="row between"><span class="h-title">주의 알림</span><button class="toggle on"></button></div>`)}
      ${T.card(`<div class="row between"><span class="h-title">일일 다이제스트</span><button class="toggle"></button></div>`)}
    </div>
  </div>`);

// 2026-08-27 — Senior settings-textsize와 같은 textsize-option 컴포넌트로
// 교체. 이전엔 선택 상태가 전혀 안 보이는 정적 버튼 2개였다(class="btn
// primary"는 실제 CSS 규칙이 없어 아무 효과도 없었음) — 같은 개념(글자
// 크기)을 다루는 화면이 앱마다 다른 컴포넌트를 쓸 이유가 없어 통일한다.
G("accessibility", "설정", "접근성", "96", "글자 크기 설정.",
  "Guardian도 정보 밀도가 높지만 접근성 옵션은 동일 제공.",
  "Senior보다 옵션 단계는 단순화(2단계) — 컴포넌트는 Senior와 동일한 textsize-option 재사용.", ["보통", "큰 글자"], (ctx, state) => {
    const descs = { "보통": "가장 많이 선택해요.", "큰 글자": "더 크게 보실 수 있어요." };
    const sizes = { "보통": 22, "큰 글자": 28 };
    return `
  ${T.topBar("접근성")}
  <div class="scr">
    <div class="stack md">
      ${["보통", "큰 글자"].map((s) => `
        <button class="textsize-option ${s === state ? "active" : ""}" data-state="${s}">
          ${s === state ? `<span class="chk">${T.msi("check")}</span>` : `<span style="width:22px"></span>`}
          <span class="txt"><span class="tt">${s}</span><span class="ds">${descs[s]}</span></span>
          <span class="sample" style="font-size:${sizes[s]}px">A</span>
        </button>`).join("")}
    </div>
  </div>`; });

G("account", "설정", "계정", "97", "계정 정보 확인.",
  "라벨-값 행 패턴 재사용.", "동일 컴포넌트.", null, (ctx) => `
  ${T.topBar("계정")}
  <div class="scr">
    ${T.card(`<div class="row between"><span class="body-sm">전화번호</span><span class="body">010-9876-5432</span></div>`)}
  </div>`);

G("manage-elders", "설정", "연결된 어르신 관리", "98", "연결 해제 등 관리.",
  "해제는 위험 행동 — 확인 다이얼로그 연결.",
  "각 항목에 해제 버튼, 누르면 connect-remove 다이얼로그.", null, (ctx) => `
  ${T.topBar("연결된 어르신 관리")}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    <div class="stack" style="padding-top:8px">
      ${ONDAM_DATA.elders.map((e) => T.listRow({ leftBadge: T.iconBadgeTint("person", "primary", "sm"), title: e.name, sub: "연결됨", right: `<button class="btn ghost" style="width:auto;padding:4px 8px" data-nav="guardian.connect-remove">해제</button>` })).join("")}
    </div>
  </div>`);
