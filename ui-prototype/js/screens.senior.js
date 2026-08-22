// Senior screen registry. 56 requested screen concepts are covered by 45
// interactive screen ids — a handful of near-duplicate result screens
// (Normal/Easy home, document/message risk results, monthly/yearly stats,
// welfare search states) are modeled as state-tabs on ONE screen instead of
// separate ids, matching how the real code already merges them (e.g.
// `home_tab_page.dart` branches Normal/Easy on the same page). Each entry's
// `spec` field lists which numbered items from the request it covers.
const SENIOR_SCREENS = [];
function S(id, cat, title, spec, purpose, ref, decision, states, render) {
  SENIOR_SCREENS.push({ id: "senior." + id, app: "senior", cat, title, spec, purpose, ref, decision, states: states || ["기본"], render });
}

// ---------- Authentication ----------
S("auth-login", "인증", "로그인", "1", "재방문 사용자의 첫 진입점 — 전화번호 로그인으로 안내.",
  "WWIT 금융앱: 로고 + 단일 CTA로 시작 화면 단순화.",
  "선택지를 1개(전화번호로 시작)만 두어 고민 없이 다음으로 넘어가게 함.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("shield", "primary", "lg")}
    <h1 class="h-display" style="margin-top:16px">온담</h1>
    <p class="body-sm" style="margin-bottom:32px">어르신을 위한 안심 생활 비서</p>
    ${T.button("전화번호로 시작하기", { variant: "accent", nav: "senior.auth-phone", large: true })}
  </div>`);

S("auth-phone", "인증", "전화번호 입력", "2", "실제 코드의 phone_input_page — 로그인/PIN설정/PIN재입력을 한 화면에서 orchestrate.",
  "Toss/네이버페이류: 숫자 키패드 자동 포커스.",
  "전화번호 형식 자동 하이픈, 다음 버튼은 11자리 입력 전까지 비활성.", null, (ctx) => `
  ${T.topBar("전화번호 입력")}
  <div class="scr">
    <p class="body" style="margin-bottom:20px">가입하신 전화번호를 입력해주세요</p>
    <div class="field"><input type="tel" value="010-1234-5678" readonly /></div>
    <div style="margin-top:28px">${T.button("다음", { variant: "accent", nav: "senior.auth-pin-entry", large: true })}</div>
  </div>`);

S("auth-pin-entry", "인증", "PIN 입력", "3", "재방문 사용자 인증 — 4자리 PIN.",
  "PIN 입력은 항상 큰 점+큰 숫자패드, 오류 시 흔들림 애니메이션.",
  "실수 방지를 위해 지우기 버튼을 별도 배치, 5회 실패 시 안내 문구 노출.", ["입력 중", "오류"], (ctx, state) => `
  ${T.topBar("PIN 입력", { back: false })}
  <div class="scr" style="display:flex;flex-direction:column;min-height:calc(100% - 60px)">
    <p class="body" style="text-align:center">PIN 번호 4자리를 입력해주세요</p>
    ${T.pinDots(state === "오류" ? 4 : 2, 4, state === "오류")}
    ${state === "오류" ? `<p class="body-sm" style="text-align:center;color:var(--danger)">PIN이 올바르지 않아요 (1회 실패)</p>` : ""}
    ${T.keypad("senior.home", "senior.auth-phone")}
  </div>`);

S("auth-pin-setup", "인증", "PIN 설정", "4", "최초 가입 시 PIN 생성 — 1차 입력 후 동일하게 재입력 확인.",
  "PIN 설정은 재입력을 요구해 오타로 인한 잠김을 예방(Apple HIG).",
  "\"다시 한 번 입력해주세요\" 문구로 지금이 확인 단계임을 명확히.", ["처음 입력", "다시 확인"], (ctx, state) => `
  ${T.topBar("PIN 설정")}
  <div class="scr" style="display:flex;flex-direction:column;min-height:calc(100% - 60px)">
    <p class="body" style="text-align:center">${state === "처음 입력" ? "사용하실 PIN 번호 4자리를 입력해주세요" : "다시 한 번 입력해주세요"}</p>
    ${T.pinDots(state === "처음 입력" ? 3 : 4, 4, false)}
    ${T.keypad("senior.onboard-welcome")}
  </div>`);

S("auth-error", "인증", "로그인 오류", "5", "인증 실패/세션 만료 안내.",
  "GOV.UK 오류 패턴: 무슨 일 + 다음 행동.",
  "재시도 버튼을 화면당 하나만 크게 배치, 문의처 링크는 보조로.", null, (ctx) => `
  <div class="scr center">
    ${T.msi("error", "")}
    <h2 class="h1" style="margin-top:12px">로그인에 실패했어요</h2>
    <p class="body-sm" style="margin-bottom:28px">전화번호 또는 PIN을 다시 확인해주세요</p>
    ${T.button("다시 시도하기", { variant: "accent", nav: "senior.auth-phone", large: true })}
    <button class="btn ghost" data-nav="senior.auth-error.help" style="margin-top:8px">계속 문제가 있나요?</button>
  </div>`);

S("auth-confirm", "인증", "계정 생성/확인", "6", "신규 가입 시 입력 정보 최종 확인.",
  "정보 확인 화면은 수정 가능함을 명시(연필 아이콘).",
  "약관 동의는 필수 1개만 체크박스로, 나머지는 안내 텍스트로 대체.", null, (ctx) => `
  ${T.topBar("정보 확인")}
  <div class="scr">
    ${T.card(`
      <div class="row between"><span class="body-sm">이름</span><span class="body">홍길동</span></div>
      <div style="height:12px"></div>
      <div class="row between"><span class="body-sm">전화번호</span><span class="body">010-1234-5678</span></div>
    `)}
    <div style="margin-top:24px">${T.button("가입 완료하기", { variant: "accent", nav: "senior.onboard-welcome", large: true })}</div>
  </div>`);

// ---------- Onboarding ----------
S("onboard-welcome", "온보딩", "환영", "7", "첫 실행 환영 + 온보딩 시작.",
  "GrandPad: 첫 화면에서 앱의 역할을 한 문장으로.",
  "\"무엇을 도와드릴까요\" 대신 온담이 하는 일을 그림+한 문장으로.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("waving_hand", "accent", "lg")}
    <h1 class="h1" style="margin-top:16px">환영합니다</h1>
    <p class="body" style="margin-bottom:32px">온담이 어르신의 안전한 생활을<br>도와드릴게요</p>
    ${T.button("시작하기", { variant: "accent", nav: "senior.onboard-accessibility", large: true })}
  </div>`);

S("onboard-accessibility", "온보딩", "접근성 설정", "8", "접근성 옵션 소개 화면.",
  "설정 안에 숨기지 않고 온보딩에 노출(Behance 툭,안부 — 글자 크기 선택이 온보딩에 있음).",
  "핵심 옵션(글자 크기, 쉬운 모드)만 먼저 보여주고 나머지는 나중에 설정에서.", null, (ctx) => `
  ${T.topBar("접근성 설정", { back: false })}
  <div class="scr">
    <p class="body" style="margin-bottom:20px">편하게 보실 수 있도록 도와드릴게요</p>
    <div class="stack md">
      ${T.card(`<div class="row"><div>${T.iconBadgeTint("format_size", "primary")}</div><div style="flex:1"><div class="h-title">글자 크기</div><div class="body-sm">더 크게 보실 수 있어요</div></div>${T.msi("chevron_right")}</div>`, "")}
      ${T.card(`<div class="row"><div>${T.iconBadgeTint("visibility", "secondary")}</div><div style="flex:1"><div class="h-title">쉬운 모드</div><div class="body-sm">더 간단한 화면으로 볼게요</div></div>${T.msi("chevron_right")}</div>`, "")}
    </div>
    <div style="margin-top:28px">${T.button("다음", { variant: "accent", nav: "senior.onboard-textsize", large: true })}</div>
  </div>`);

S("onboard-textsize", "온보딩", "글자 크기", "9", "글자 크기 선택, 실시간 미리보기.",
  "WCAG: 200% 확대까지 레이아웃이 깨지지 않아야 함.",
  "4단계 버튼 + 즉시 반영되는 미리보기 문장으로 결과를 바로 확인.", ["보통", "크게", "아주 크게"], (ctx, state) => {
    const size = { 보통: "16px", 크게: "20px", "아주 크게": "26px" }[state];
    return `
  ${T.topBar("글자 크기")}
  <div class="scr">
    ${T.card(`<p style="font-size:${size};font-weight:700;margin:0">이렇게 보여드릴게요</p>`)}
    <div class="stack" style="margin-top:16px">
      ${["보통", "크게", "아주 크게"].map((s) => `<button class="btn ${s === state ? "accent" : "secondary"}" data-state="${s}">${s}</button>`).join("")}
    </div>
    <div style="margin-top:28px">${T.button("다음", { variant: "accent", nav: "senior.onboard-easymode", large: true })}</div>
  </div>`; });

S("onboard-easymode", "온보딩", "Easy Mode", "10", "쉬운 모드 소개 + 즉시 켜고 끌 수 있는 토글.",
  "핵심 UX 전략으로 다루되 강요하지 않음(ui-principles.md Easy Mode 원칙 8).",
  "토글 기본값 off, 설명은 2줄 이내.", ["off", "on"], (ctx, state) => `
  ${T.topBar("쉬운 모드")}
  <div class="scr">
    ${T.card(`<div class="row"><div style="flex:1"><div class="h-title">쉬운 모드로 볼까요?</div><div class="body-sm">글자와 버튼이 커지고 화면이 더 단순해져요</div></div><button class="toggle ${state === "on" ? "on" : ""}" data-state="${state === "on" ? "off" : "on"}"></button></div>`)}
    <div style="margin-top:28px">${T.button("다음", { variant: "accent", nav: "senior.onboard-profile", large: true })}</div>
  </div>`);

S("onboard-profile", "온보딩", "내 정보", "11", "이름/생년 등 최소 정보 입력.",
  "온보딩에서는 지금 필요한 선택만(원칙 5).",
  "필수 2개 필드만, 나머지는 나중에 설정에서.", null, (ctx) => `
  ${T.topBar("내 정보")}
  <div class="scr">
    <div class="field" style="margin-bottom:16px"><label>이름</label><input value="홍길동" readonly /></div>
    <div class="field"><label>태어난 해</label><input value="1952" readonly /></div>
    <div style="margin-top:28px">${T.button("다음", { variant: "accent", nav: "senior.onboard-guardian", large: true })}</div>
  </div>`);

S("onboard-guardian", "온보딩", "보호자 연결", "12", "보호자 연결 안내, 건너뛰기 가능.",
  "Behance 툭,안부 IA — 계정 추가/초대 링크가 로그인 직후 옵션으로 제공.",
  "지금 연결하지 않아도 나중에 더보기에서 가능함을 명시해 부담을 줄임.", null, (ctx) => `
  ${T.topBar("보호자 연결")}
  <div class="scr center">
    ${T.iconBadgeTint("family_restroom", "primary", "lg")}
    <h2 class="h1" style="margin-top:14px">보호자와 연결해보세요</h2>
    <p class="body-sm" style="margin-bottom:24px">위험한 문자나 문서를 발견하면<br>보호자에게 알려드려요</p>
    ${T.button("QR 코드로 연결하기", { variant: "accent", nav: "senior.qr-generate", large: true })}
    <button class="btn ghost" data-nav="senior.onboard-done" style="margin-top:8px">나중에 할게요</button>
  </div>`);

S("onboard-done", "온보딩", "온보딩 완료", "13", "온보딩 종료, 홈으로 진입.",
  "GrandPad 90/90: 온보딩 끝에서 다음에 뭘 할 수 있는지 명확히.",
  "완료 화면에 체크 아이콘 + 첫 기능 안내 한 줄.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">준비가 끝났어요</h2>
    <p class="body-sm" style="margin-bottom:28px">이제 온담을 사용하실 수 있어요</p>
    ${T.button("시작하기", { variant: "accent", nav: "senior.home", large: true })}
  </div>`);

// ---------- Home ----------
S("info", "홈", "정보 (빈 상태)", "요청 목록 외 — 실제 코드 info_tab_page.dart 대응", "탭 화면 — 아직 domain/data 계층이 없어 정직한 빈 상태로 둠(실제 코드 그대로).",
  "정직한 빈 상태 — Mock으로 채우지 않음(원칙 유지).",
  "요청된 56개 화면 목록엔 없지만 실제 4탭 구조상 존재해 함께 등록.", null, (ctx) => `
  ${T.topBar("정보", { back: false })}
  <div class="scr">${T.emptyState("info", "아직 준비된 정보가 없어요", "곧 맞춤 정보를 보여드릴게요")}</div>
  ${T.bottomNavSenior("senior.info")}`);

S("home", "홈", "홈 (Normal / Easy Mode)", "14, 15", "핵심 기능 진입점 + 긴급 도움. Easy Mode는 같은 화면의 토글(실제 코드와 동일 구조).",
  "Behance 툭,안부: 아이콘을 원형 배지에 담아 터치 대상 명확화.",
  "쉬운모드 토글은 항상 상단 고정, 긴급 버튼은 emergency 토큰으로 error와 분리.", ["Normal", "Easy"], (ctx, state) => {
    const easy = state === "Easy";
    const features = [
      { icon: "document_scanner", label: "문서 촬영", tone: "primary", nav: "senior.doc-start" },
      { icon: "sms", label: "문자 확인", tone: "primary", nav: "senior.msg-list" },
      { icon: "place", label: "경로당 찾기", tone: "secondary", nav: "senior.welfare-region" },
    ];
    return `
  <div class="scr flush" data-app="senior" data-easy="${easy}" style="position:relative;min-height:100%">
    <div class="scr">
      ${T.card(`<div class="row"><div style="flex:1"><span class="h-title">쉬운 모드</span></div><button class="toggle ${easy ? "on" : ""}" data-state="${easy ? "Normal" : "Easy"}"></button></div>`)}
      <div style="height:16px"></div>
      ${easy
        ? `<div class="stack md">
            ${features.map((f) => `<div class="easy-btn" data-nav="${f.nav}">${T.msi(f.icon)}<span class="lbl">${f.label}</span></div>`).join("")}
            <div class="easy-btn coral" data-nav="senior.emergency">${T.msi("crisis_alert", "fill")}<span class="lbl">긴급 도움</span></div>
          </div>`
        : `<div class="feature-grid">${features.map((f) => `<div class="feature-card" data-nav="${f.nav}">${T.iconBadgeTint(f.icon, f.tone)}<span class="lbl">${f.label}</span></div>`).join("")}</div>`}
    </div>
    ${!easy ? `<div class="fab corner" data-nav="senior.emergency">${T.msi("crisis_alert", "fill")}</div>` : ""}
    <div class="fab" data-nav="senior.voice">${T.msi("mic")}</div>
  </div>
  ${T.bottomNavSenior("senior.home")}`; });

S("emergency", "홈", "긴급 도움", "16", "긴급 상황 시 도움 요청 시트.",
  "확인 다이얼로그는 되돌릴 수 없는 행동에만(원칙 7) — 전화 연결 전 1회 확인.",
  "보호자/119 버튼을 크고 색으로 구분, 취소는 항상 가능.", null, (ctx) => `
  <div class="scr" data-app="senior" style="position:relative;min-height:100%">
    ${T.sheet(`
      <h2 class="h1" style="text-align:center">어떤 도움이 필요하세요?</h2>
      <div class="stack md" style="margin-top:16px">
        ${T.button("119 신고하기", { variant: "emergency", icon: "crisis_alert", large: true })}
        ${T.button("보호자에게 전화하기", { variant: "accent", icon: "call", large: true })}
        <button class="btn ghost" data-back>취소</button>
      </div>`)}
  </div>`);

S("voice", "홈", "음성 비서", "17", "음성 명령 대체 입력 경로.",
  "Google Conversation Design: 단순 조회는 확인 없이 바로 실행.",
  "듣고 있다는 상태를 파형 애니메이션 대신 큰 마이크 아이콘 pulsing으로 단순화.", null, (ctx) => `
  <div class="scr center" data-app="senior" data-easy="true">
    ${T.iconBadge("mic", "accent", "lg")}
    <h2 class="h1" style="margin-top:16px">듣고 있어요</h2>
    <p class="body">"문서를 촬영해줘"처럼<br>말씀해보세요</p>
    <button class="btn ghost" data-back style="margin-top:20px">닫기</button>
  </div>`);

// ---------- Document ----------
S("doc-start", "문서 분석", "문서 분석 시작", "18", "문서 촬영 진입 안내.",
  "카메라 진입 전 무엇을 촬영하면 되는지 1문장 안내(원칙 4).",
  "고지서 예시 아이콘 + \"고지서, 안내문을 촬영해주세요\".", null, (ctx) => `
  ${T.topBar("문서 분석")}
  <div class="scr center">
    ${T.iconBadgeTint("description", "primary", "lg")}
    <p class="body" style="margin:16px 0 28px">고지서나 안내문을<br>촬영하면 위험한 내용이 있는지<br>확인해드려요</p>
    ${T.button("촬영 시작하기", { variant: "accent", nav: "senior.doc-camera", large: true, icon: "photo_camera" })}
  </div>`);

S("doc-camera", "문서 분석", "카메라", "19", "실제 촬영 화면.",
  "카메라는 최소 UI — 셔터만 크게, 플래시는 아이콘+텍스트 병행(기존 결정 유지).",
  "셔터 버튼 80px 이상, 화면 대부분을 프리뷰가 차지.", null, (ctx) => `
  <div class="scr flush" style="background:#111;min-height:100%;display:flex;flex-direction:column;color:#fff">
    <div class="top-bar" style="color:#fff"><button class="back" style="color:#fff" data-back>${T.msi("close")}</button><h1 style="color:#fff">문서 촬영</h1><button class="right-action" style="color:#fff">${T.msi("flash_off")}</button></div>
    <div style="flex:1;display:flex;align-items:center;justify-content:center;color:#666">문서를 화면 안에 맞춰주세요</div>
    <div style="display:flex;justify-content:center;padding:24px"><button data-nav="senior.doc-captured" style="width:76px;height:76px;border-radius:50%;background:#fff;border:6px solid #999"></button></div>
  </div>`);

S("doc-captured", "문서 분석", "촬영 완료", "20", "촬영 결과 확인, 재촬영/다음.",
  "실수 방지 — 바로 분석하지 않고 확인 단계를 둠.",
  "큰 미리보기 + 재촬영/사용하기 버튼을 동급 크기로.", null, (ctx) => `
  ${T.topBar("촬영 확인")}
  <div class="scr">
    <div style="aspect-ratio:3/4;background:var(--surface);border-radius:var(--r-lg);display:flex;align-items:center;justify-content:center;color:var(--text-disabled)">${T.msi("description")}</div>
    <div class="stack" style="margin-top:20px">
      ${T.button("이 사진 사용하기", { variant: "accent", nav: "senior.doc-analyzing", large: true })}
      ${T.button("다시 촬영하기", { variant: "secondary", nav: "senior.doc-camera" })}
    </div>
  </div>`);

S("doc-analyzing", "문서 분석", "분석 중", "21", "AI 분석 진행 상태.",
  "중요 작업은 스피너+설명 텍스트 병행(기존 결정 A 유지).",
  "\"무슨 일이 일어나고 있는지\" 문장으로 불안감 감소.", null, (ctx) => `
  <div class="scr center">${T.loadingState("문서를 꼼꼼히 확인하고 있어요")}<p class="body-sm">잠시만 기다려주세요</p></div>`);

S("doc-result", "문서 분석", "분석 결과 / 위험 문서 결과", "22, 23", "분석 결과 — 위험도별 표현.",
  "색상 단독 금지(원칙 6) — 색+아이콘+텍스트+행동안내 4중 표현.",
  "위험일 때만 \"보호자에게 확인\" 행동 문구 추가.", ["안전", "위험"], (ctx, state) => {
    const isDanger = state === "위험";
    return `
  ${T.topBar("분석 결과")}
  <div class="scr">
    ${isDanger
      ? T.alertCard("dangerous", "위험해요", "이 문서는 금전이나 개인정보를 요구하고 있어요.", "혼자 결정하지 말고 보호자에게 확인해 보세요.")
      : T.alertCard("safe", "안전한 문서예요", "특별히 위험한 내용은 발견되지 않았어요.")}
    <div style="height:20px"></div>
    ${T.card(`<div class="body-sm" style="margin-bottom:8px">한국전력 전기요금 고지서</div><div class="h-title">87,500원</div><div class="body-sm">2026.08.25</div>`)}
    <div style="margin-top:24px">${T.button(isDanger ? "보호자에게 알리기" : "확인 완료", { variant: "accent", nav: "senior.doc-confirm", large: true })}</div>
  </div>`; });

S("doc-confirm", "문서 분석", "확인 완료", "24", "사용자가 결과를 확인했음을 기록.",
  "완료 피드백은 짧고 명확하게.",
  "체크 아이콘 + \"기록에 저장됐어요\" 한 줄.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">확인 완료</h2>
    <p class="body-sm" style="margin-bottom:24px">기록에 저장됐어요</p>
    ${T.button("홈으로", { variant: "accent", nav: "senior.home", large: true })}
  </div>`);

S("doc-retake", "문서 분석", "다시 촬영", "25", "재촬영 확인 다이얼로그.",
  "되돌릴 수 없는 건 아니지만 실수 방지를 위해 1회 확인.",
  "촬영한 사진이 사라진다는 점을 명시.", null, (ctx) => `
  <div class="scr" style="position:relative;min-height:100%">
    ${T.dialog("다시 촬영하시겠어요?", "지금 촬영한 사진은 사라져요.", `${T.button("취소", { variant: "secondary" })}${T.button("다시 촬영", { variant: "accent", nav: "senior.doc-camera" })}`)}
  </div>`);

S("doc-multi", "문서 분석", "다중 문서 진행", "26", "여러 장 촬영 진행 상태.",
  "진행 상태는 숫자+점으로 단순 표시.",
  "\"2장 촬영했어요\" + 추가/완료 두 선택지만.", null, (ctx) => `
  ${T.topBar("문서 촬영")}
  <div class="scr">
    ${T.card(`<div class="row between"><span class="h-title">2장 촬영했어요</span>${T.riskBadge("safe")}</div>`)}
    <div class="stack" style="margin-top:20px">
      ${T.button("한 장 더 촬영하기", { variant: "secondary", nav: "senior.doc-camera", icon: "add_a_photo" })}
      ${T.button("분석 시작하기", { variant: "accent", nav: "senior.doc-analyzing", large: true })}
    </div>
  </div>`);

// ---------- Message ----------
S("msg-list", "문자 분석", "문자 확인", "27", "문자 분석 진입 — 최근 확인한 문자 목록.",
  "실제 코드 message_check 기능과 대응.",
  "리스트 상단에 \"새 문자 확인하기\" CTA를 고정.", ["불러오는 중", "목록", "빈 목록"], (ctx, state) => `
  ${T.topBar("문자 확인")}
  <div class="scr">
    ${T.button("새 문자 확인하기", { variant: "accent", nav: "senior.msg-result", large: true, icon: "sms" })}
    <div style="height:20px"></div>
    ${state === "불러오는 중" ? T.loadingState() : state === "빈 목록" ? T.emptyState("sms", "아직 확인한 문자가 없어요", "새 문자를 확인해보세요") : `
    <div class="stack">
      ${ONDAM_DATA.messages.slice(0, 3).map((m) => T.listRow({ leftBadge: T.iconBadgeTint("sms", "primary", "sm"), title: m.preview.slice(0, 16) + "…", sub: m.date, nav: "senior.msg-detail" })).join("")}
    </div>`}
  </div>`);

S("msg-result", "문자 분석", "문자 분석 결과 (안전/주의/위험)", "28, 29, 30", "위험도별 문자 분석 결과.",
  "\"⚠ 주의가 필요해요 — 이유 — 행동 안내\" 3단 구조(사용자 지정 예시 반영).",
  "행동 안내 문장은 위험/주의일 때만 노출, 안전은 안심 문구로 대체.", ["안전", "주의", "위험"], (ctx, state) => {
    const map = { 안전: "safe", 주의: "caution", 위험: "dangerous" };
    const level = map[state];
    const copy = { safe: ["안전한 문자예요", "특별히 위험한 내용은 없어요.", ""], caution: ["주의가 필요해요", "공공기관을 사칭하는 것으로 의심돼요.", "혼자 결정하지 말고 보호자에게 확인해 보세요."], dangerous: ["위험해요", "이 문자는 돈이나 개인정보를 요구하고 있어요.", "절대 링크를 누르거나 답장하지 마세요. 보호자에게 바로 알릴게요."] }[level];
    return `
  ${T.topBar("문자 분석 결과")}
  <div class="scr">
    ${T.alertCard(level, copy[0], copy[1], copy[2])}
    <div style="height:16px"></div>
    ${T.card(`<div class="body-sm">보낸 사람</div><div class="h-title">010-****-2231</div><div class="body-sm" style="margin-top:8px">[Web발신] 고객님 명의로 개설된 계좌가...</div>`)}
    <div style="margin-top:24px">${T.button(level === "safe" ? "확인 완료" : "보호자에게 알리기", { variant: "accent", nav: level === "safe" ? "senior.doc-confirm" : "senior.msg-guardian-notice", large: true })}</div>
  </div>`; });

S("msg-detail", "문자 분석", "문자 분석 상세", "31", "지난 문자 분석 기록 상세.",
  "신뢰도는 위험도와 다른 색 계열로 별도 표시(원칙 6 연결 노트).",
  "AppConfidenceIndicator와 동일하게 위험 배지와 분리해 배치.", null, (ctx) => `
  ${T.topBar("문자 상세")}
  <div class="scr">
    ${T.alertCard("dangerous", "위험해요", "이 문자는 돈이나 개인정보를 요구하고 있어요.")}
    <div style="height:16px"></div>
    ${T.card(`<div class="body-sm" style="margin-bottom:6px">분석 신뢰도</div><div class="row between"><span class="body">높음</span><span class="body-sm">95%</span></div><div class="confidence-bar" style="margin-top:6px"><i style="width:95%"></i></div>`)}
    <div style="height:16px"></div>
    ${T.card(`<div class="body-sm">전체 내용</div><div class="body" style="margin-top:6px">[Web발신] 고객님 명의로 개설된 계좌가 확인되어 즉시 확인이 필요합니다. 아래 링크를 클릭해주세요.</div>`)}
  </div>`);

S("msg-guardian-notice", "문자 분석", "보호자 알림 안내", "32", "보호자에게 알림이 전송됐음을 안내.",
  "행동의 결과를 명확히 알려줘 불안감 감소.",
  "\"OO님께 알려드렸어요\"로 구체적으로.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">보호자에게 알렸어요</h2>
    <p class="body-sm" style="margin-bottom:24px">아드님께 문자 내용을 전달했어요</p>
    ${T.button("홈으로", { variant: "accent", nav: "senior.home", large: true })}
  </div>`);

// ---------- Records ----------
S("records", "기록", "기록 목록", "33", "탭 화면 — 전체 분석 기록.",
  "Guardian과 동일한 위험도 배지 체계 공유(일관성).",
  "기록은 최신순, 필터는 상단 아이콘 버튼으로 진입.", ["불러오는 중", "목록", "빈 기록", "오류"], (ctx, state) => `
  ${T.topBar("기록", { back: false, right: `<button class="right-action" data-nav="senior.records-filter">${T.msi("tune")}</button>` })}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    ${state === "불러오는 중" ? T.loadingState() : state === "오류" ? T.errorState("기록을 불러오지 못했어요", "senior.records") : state === "빈 기록" ? T.emptyState("history", "아직 기록이 없어요", "문서나 문자를 확인하면 여기에 쌓여요") : `
    <div class="stack" style="padding-top:8px">
      ${[...ONDAM_DATA.documents.filter((d) => d.elderId === "e1"), ...ONDAM_DATA.messages.filter((m) => m.elderId === "e1")].map((r) => T.listRow({ leftBadge: T.iconBadgeTint(r.type ? "description" : "sms", "primary", "sm"), title: r.title || r.preview.slice(0, 18) + "…", sub: r.date, right: T.riskBadge(r.risk), nav: "senior.records-detail" })).join("")}
    </div>`}
  </div>
  ${T.bottomNavSenior("senior.records")}`);

S("records-filter", "기록", "기록 필터", "34", "위험도/기간 필터 시트.",
  "선택지 3개 이하로 제한(원칙 5).",
  "안전/주의/위험 3개 칩만 제공, 복잡한 날짜 범위는 생략.", null, (ctx) => `
  <div class="scr" style="position:relative;min-height:100%">
    ${T.sheet(`
      <h3 class="h-title">필터</h3>
      <div class="chip-row" style="margin-top:14px">${["전체", "안전", "주의", "위험"].map((l, i) => `<button class="chip ${i === 0 ? "active" : ""}">${l}</button>`).join("")}</div>
      <div style="margin-top:20px">${T.button("적용하기", { variant: "accent", nav: "senior.records" })}</div>
    `)}
  </div>`);

S("records-detail", "기록", "기록 상세 (확인 완료 상태)", "35, 36", "기록 상세 + 확인 여부.",
  "위험 기록은 확인 여부를 명확한 배지로.",
  "확인 완료 버튼을 누르면 상태가 즉시 바뀌는 걸 보여줌(Undo 가능 원칙 검토 대상).", ["미확인", "확인완료"], (ctx, state) => `
  ${T.topBar("기록 상세")}
  <div class="scr">
    ${T.alertCard("dangerous", "위험해요", "이 문서는 금전이나 개인정보를 요구하고 있어요.")}
    <div style="height:16px"></div>
    ${T.card(`<div class="row between"><span class="body-sm">상태</span>${state === "확인완료" ? `<span class="badge-dot">확인 완료</span>` : `<span class="body-sm" style="color:var(--warning)">미확인</span>`}</div>`)}
    <div style="margin-top:20px">${state === "미확인" ? T.button("확인 완료로 표시", { variant: "accent", nav: "senior.records-detail", large: true, attrs: `data-state="확인완료"` }) : ""}</div>
  </div>`);

// ---------- Statistics ----------
S("stats-home", "통계", "통계 홈 (빈 통계 포함)", "37, 41", "이번 달 요약 + 요금 통계 진입.",
  "WWIT 네이버페이 자산 화면 — 요약 카드 → 세부 순.",
  "핵심 숫자(이번 달 요금)를 최상단에, 세부는 탭해서 진입.", ["기본", "빈 상태"], (ctx, state) => `
  ${T.topBar("통계", { back: false })}
  <div class="scr flush" style="padding:0 var(--sp-lg) var(--sp-xxl)">
    ${state === "빈 상태" ? T.emptyState("bar_chart", "아직 통계가 없어요", "문서를 촬영하면 요금 통계를 볼 수 있어요") : `
    <div style="padding-top:8px">
      ${T.feeHero("8월 요금", 87500, -12500)}
      <div style="height:16px"></div>
      <div class="card" data-nav="senior.stats-fee"><div class="row between"><span class="h-title">요금 통계 자세히 보기</span>${T.msi("chevron_right")}</div></div>
    </div>`}
  </div>
  ${T.bottomNavSenior("senior.more")}`);

S("stats-fee", "통계", "요금 통계 (월별/연별)", "38, 39, 40", "월별·연별 요금 추이.",
  "숫자 요약을 반드시 그래프와 함께(사용자 지정 예시: \"8월 요금 87,500원, 지난달보다 12,500원 적어요\").",
  "그래프만 보여주지 않고 핵심 문장을 카드 최상단에 고정.", ["월별", "연별"], (ctx, state) => {
    const isMonthly = state === "월별";
    const data = isMonthly ? ONDAM_DATA.feeStats.monthly : ONDAM_DATA.feeStats.yearly;
    return `
  ${T.topBar("요금 통계")}
  <div class="scr">
    <div class="chip-row">${["월별", "연별"].map((l) => `<button class="chip ${l === state ? "active" : ""}" data-state="${l}">${l}</button>`).join("")}</div>
    <div style="height:14px"></div>
    ${T.feeHero(isMonthly ? "8월 요금" : "2026년 요금", isMonthly ? 87500 : 1980000, isMonthly ? -12500 : -300000, isMonthly ? "지난달보다" : "작년보다")}
    <div style="height:16px"></div>
    ${T.lineChart(data, isMonthly ? "m" : "y")}
    <div style="height:20px"></div>
    ${T.statGrid([T.statCard("payments", "primary", won(ONDAM_DATA.feeStats.total), "총 금액"), T.statCard("insights", "secondary", won(ONDAM_DATA.feeStats.avg), "평균 금액"), T.statCard("receipt_long", "success", ONDAM_DATA.feeStats.count + "건", "고지서 수")])}
  </div>`; });

S("stats-detail", "통계", "통계 상세", "42", "개별 고지서 상세.",
  "원본 항목을 구조화된 표로 나열(현재 코드 AppInfoRow 패턴 유지).",
  "핵심 금액을 상단에 강조 후 세부 항목 나열.", null, (ctx) => `
  ${T.topBar("고지서 상세")}
  <div class="scr">
    ${T.card(`<div class="body-sm">한국전력 전기요금</div><div class="h-display" style="margin-top:4px">87,500원</div><div class="body-sm">2026.08.25</div>`)}
    <div style="height:16px"></div>
    ${T.card(`<div class="row between"><span class="body-sm">사용량</span><span class="body">312kWh</span></div><div style="height:10px"></div><div class="row between"><span class="body-sm">전월 대비</span><span class="body">-12,500원</span></div>`)}
  </div>`);

// ---------- Welfare Center ----------
S("welfare-region", "경로당", "내 지역", "43", "지역 설정 후 검색 진입.",
  "현재 위치 자동 감지 + 수동 변경 옵션 병행.",
  "지역명을 크게, 변경 버튼은 보조로.", null, (ctx) => `
  ${T.topBar("내 지역")}
  <div class="scr center">
    ${T.iconBadgeTint("place", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">서울시 OO구</h2>
    <p class="body-sm" style="margin-bottom:24px">현재 위치로 확인했어요</p>
    ${T.button("경로당 찾기", { variant: "accent", nav: "senior.welfare-search", large: true })}
  </div>`);

S("welfare-search", "경로당", "경로당 검색 (결과/결과 없음)", "44, 45, 46", "검색 진행 → 결과 표시.",
  "검색 흐름 자체를 상태로 보여줌(로딩→결과/결과없음).",
  "결과 없음일 때도 다음 행동(반경 넓히기)을 제공.", ["불러오는 중", "결과 있음", "결과 없음"], (ctx, state) => `
  ${T.topBar("경로당 검색")}
  <div class="scr flush" style="padding:0 var(--sp-lg) var(--sp-xxl)">
    <div style="padding:var(--sp-md) 0">${T.card(`<div class="row">${T.msi("search")}<span class="body-sm">근처 경로당 검색 중...</span></div>`)}</div>
    ${state === "불러오는 중" ? T.loadingState("경로당을 찾고 있어요") : state === "결과 없음" ? T.emptyState("search_off", "근처에 경로당이 없어요", "검색 범위를 넓혀보세요", "범위 넓히기", "senior.welfare-search") : `
    <div class="stack">${ONDAM_DATA.welfareCenters.map((w) => T.listRow({ leftBadge: T.iconBadgeTint("place", "secondary", "sm"), title: w.name, sub: `${w.dist} · ${w.open ? "운영 중" : "운영 종료"}`, nav: "senior.welfare-detail" })).join("")}</div>`}
  </div>`);

S("welfare-detail", "경로당", "경로당 상세 (전화걸기)", "47, 48", "상세 정보 + 전화 연결.",
  "전화 연결 전 상대방 이름을 다시 보여줘 실수 예방.",
  "전화걸기는 확인 다이얼로그로 한 번 더 확인.", ["기본", "전화 확인"], (ctx, state) => `
  ${T.topBar("행복경로당")}
  <div class="scr" style="position:relative;min-height:100%">
    ${T.card(`<div class="h1">행복경로당</div><div class="body-sm" style="margin-top:4px">서울시 OO구 OO로 12 · 320m</div><div class="body-sm" style="margin-top:2px">${T.riskBadge("safe")} 운영 중</div>`)}
    <div style="margin-top:20px">${T.button("전화 걸기", { variant: "accent", nav: "senior.welfare-detail", large: true, icon: "call", attrs: `data-state="전화 확인"` })}</div>
    ${state === "전화 확인" ? T.dialog("행복경로당에 전화할까요?", "02-1234-5678", `${T.button("취소", { variant: "secondary", nav: "senior.welfare-detail" })}${T.button("전화하기", { variant: "accent" })}`) : ""}
  </div>`);

// ---------- More ----------
S("more", "더보기", "더보기", "49", "탭 화면 — 설정/프로필 진입 메뉴.",
  "메뉴는 텍스트 리스트로 단순하게, 아이콘 병행.",
  "6개 항목만, 스크롤 없이 한 화면에.", null, (ctx) => `
  ${T.topBar("더보기", { back: false })}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    <div class="stack" style="padding-top:8px">
      ${[["person", "프로필", "senior.profile"], ["family_restroom", "보호자 연결", "senior.guardian-link"], ["settings", "설정", "senior.settings"], ["accessibility_new", "접근성 설정", "senior.settings-accessibility"], ["notifications", "알림 설정", "senior.notif-settings"], ["logout", "로그아웃", "senior.more"]].map(([icon, label, nav]) => T.listRow({ leftBadge: T.iconBadgeTint(icon, "primary", "sm"), title: label, sub: "", nav })).join("")}
    </div>
  </div>
  ${T.bottomNavSenior("senior.more")}`);

S("profile", "더보기", "프로필", "50", "내 정보 확인/수정.",
  "정보 항목은 라벨-값 행으로.",
  "수정은 각 행 우측 연필 아이콘으로 진입(별도 화면 없이 인라인).", null, (ctx) => `
  ${T.topBar("프로필")}
  <div class="scr">
    ${T.card(`<div class="row between"><span class="body-sm">이름</span><span class="body">홍길동</span></div><div style="height:12px"></div><div class="row between"><span class="body-sm">전화번호</span><span class="body">010-1234-5678</span></div><div style="height:12px"></div><div class="row between"><span class="body-sm">태어난 해</span><span class="body">1952</span></div>`)}
  </div>`);

S("settings", "더보기", "설정", "51", "일반 설정 목록.",
  "설정은 카테고리별로 묶어 스크롤 부담 감소.",
  "위험한 설정(탈퇴)은 맨 아래 별도 구분.", null, (ctx) => `
  ${T.topBar("설정")}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    <div class="stack" style="padding-top:8px">
      ${T.listRow({ title: "접근성", sub: "글자 크기, 쉬운 모드", nav: "senior.settings-accessibility" })}
      ${T.listRow({ title: "알림", sub: "위험 알림, 보호자 알림", nav: "senior.notif-settings" })}
      ${T.listRow({ title: "보호자 연결", sub: "1명 연결됨", nav: "senior.connection-status" })}
    </div>
  </div>`);

S("settings-accessibility", "더보기", "접근성 설정", "52", "글자 크기/쉬운 모드 재설정.",
  "온보딩과 동일한 컴포넌트 재사용(일관성).",
  "온보딩 화면과 동일한 UI로 학습 비용 감소.", null, (ctx) => SENIOR_SCREENS.find((s) => s.id === "senior.onboard-textsize").render(ctx, "크게").replace("senior.onboard-easymode", "senior.settings"));

S("guardian-link", "더보기", "보호자 연결", "53", "보호자 연결 상태 관리 진입.",
  "연결 해제는 위험 행동으로 별도 확인(원칙 7).",
  "연결된 보호자를 카드로, 해제 버튼은 눈에 띄지 않게 하단.", null, (ctx) => `
  ${T.topBar("보호자 연결")}
  <div class="scr">
    ${T.card(`<div class="row">${T.iconBadgeTint("person", "primary", "sm")}<div style="flex:1"><div class="h-title">아드님</div><div class="body-sm">연결됨 · 2026.06.01</div></div></div>`)}
    <div style="margin-top:24px">${T.button("새 보호자 연결하기", { variant: "accent", nav: "senior.qr-generate" })}</div>
  </div>`);

S("qr-generate", "더보기", "QR 생성", "54", "보호자 연결용 QR 코드 발급.",
  "QR은 크게, 유효시간을 텍스트로 안내.",
  "5분 후 자동 만료 안내 + 재생성 버튼.", null, (ctx) => `
  ${T.topBar("QR 코드")}
  <div class="scr center">
    ${T.qrBox()}
    <p class="body-sm" style="margin:16px 0 24px">보호자에게 이 QR을 보여주세요<br>5분 후 만료돼요</p>
    ${T.button("새로고침", { variant: "secondary", nav: "senior.qr-generate" })}
  </div>`);

S("connection-status", "더보기", "연결 상태", "55", "보호자 연결 현황 확인.",
  "연결 여부를 상태 카드로 명확히.",
  "연결됨 상태에 체크 아이콘 병행.", null, (ctx) => `
  ${T.topBar("연결 상태")}
  <div class="scr">
    ${T.alertCard("safe", "보호자와 연결되어 있어요", "아드님이 위험 알림을 받고 있어요.")}
  </div>`);

S("notif-settings", "더보기", "알림 설정", "56", "알림 종류별 on/off.",
  "위험 알림은 끌 수 없도록(안전 우선) — 나머지만 토글.",
  "위험 알림 항목에 \"항상 켜짐\" 배지.", null, (ctx) => `
  ${T.topBar("알림 설정")}
  <div class="scr">
    <div class="stack md">
      ${T.card(`<div class="row between"><span class="h-title">위험 알림</span><span class="caption">항상 켜짐</span></div>`)}
      ${T.card(`<div class="row between"><span class="h-title">기록 저장 알림</span><button class="toggle on"></button></div>`)}
    </div>
  </div>`);
