// Guardian screen registry. 42 requested screen concepts covered by 25
// interactive screen ids (see SENIOR_SCREENS comment for the merge rationale
// — e.g. risk-level notification variants share one detail screen). 2026-09-01
// — 인증/온보딩 7개를 "connect" 1개로 대체하며 31→25로 줄었다.
const GUARDIAN_SCREENS = [];
function G(id, cat, title, spec, purpose, ref, decision, states, render) {
  GUARDIAN_SCREENS.push({ id: "guardian." + id, app: "guardian", cat, title, spec, purpose, ref, decision, states: states || ["기본"], render });
}

// ---------- 시작 ----------
// 2026-09-01 — 사용자 요청으로 인증(로그인/PIN 설정/PIN 입력/로그인 오류)과
// 온보딩(환영/기본 설정/온보딩 완료) 7개 화면을 삭제하고, 외부 레퍼런스
// 저장소(chanbear/gyeongjidaehoe3-main, codex/guardian-app 브랜치의
// guardian.html #connectScreen)에 있는 보호자 첫 화면 하나로 대체했다.
// 원본은 전화번호 연결 폼 + "연결 전 화면 미리보기"인데, 여기서는 그 구조를
// ui-prototype 자체 컴포넌트/토큰(T.button, .field)으로 다시 구현했다 —
// 원본 CSS/마크업을 그대로 옮기지 않는다. app.js의 enterApp()도 Guardian
// 진입점을 이 화면으로 바꿨다(기존엔 곧장 guardian.home으로 진입).
// 2026-09-01(2차) — 사용자 요청으로 "어르신 전화번호" 단일 입력을
// 보호자 본인 로그인(이름+전화번호) 두 입력 + 바로 아래 "보호자 연결하기"
// 버튼으로 변경. 실제 Flutter 앱(apps/guardian)의 흐름과 순서를 맞춘다 —
// 보호자 본인 인증이 먼저이고, 특정 어르신과의 QR 연결(elder-add/qr-scan)은
// 그다음 별도 단계라 버튼은 elder-add로 이동한다.
G("connect", "시작", "보호자 로그인 · 연결", "57", "보호자 앱 진입점 — 보호자 본인 정보 입력 후 어르신 QR 연결로 이어짐.",
  "온보딩/PIN 단계 없이 이름+전화번호 두 필드와 버튼 하나로 진입 마찰을 없앤다(기존 결정 유지) — 다만 입력 대상을 어르신이 아니라 보호자 본인으로 바꿔 실제 로그인 흐름과 맞춘다.",
  "\"보호자 연결하기\"가 주 CTA, 다음 화면(elder-add)에서 QR로 어르신을 연결한다. \"연결 전 화면 미리보기\"는 그대로 home의 \"어르신 없음\" 상태로 연결.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadgeTint("family_restroom", "primary", "lg")}
    <h1 class="h1" style="margin-top:16px">부모님 곁에<br>한 걸음 더 가까이</h1>
    <p class="body-sm" style="margin-bottom:28px">보호자 정보를 입력하고<br>어르신과 안전하게 연결하세요.</p>
    <div class="field" style="width:100%;text-align:left;margin-bottom:12px"><label>보호자 이름</label><input type="text" placeholder="홍길동" /></div>
    <div class="field" style="width:100%;text-align:left;margin-bottom:24px"><label>전화번호</label><input type="tel" placeholder="010-1234-5678" /></div>
    ${T.button("보호자 연결하기", { variant: "primary", nav: "guardian.elder-add", large: true })}
    <div style="margin-top:10px;width:100%">${T.button("연결 전 화면 미리보기", { variant: "secondary", nav: "guardian.home", attrs: `data-state="어르신 없음"` })}</div>
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
    ${T.dialog("연결을 해제할까요?", "해제하면 아버님의 활동을 더 이상 볼 수 없어요.", `${T.button("취소", { variant: "secondary", nav: "guardian.manage-elders" })}${T.button("해제하기", { variant: "emergency", nav: "guardian.manage-elders" })}`)}
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

// 2026-09-01 — 사용자 요청: "시니어앱에서 분석한 결과를 보호자용에서 본
// 것처럼 보이는 화면"이 없었다(기존엔 alertCard + 확인 상태 카드뿐, 실제
// 분석 내용이 전혀 없었음). Senior의 analysisResultBody()(위험도/신뢰도 →
// 분석 정보 → AI 요약 → 해야 할 일 → 상세정보)를 그대로 재사용해 같은
// 내용을 보호자도 보게 한다 — 실제 코드(AnalysisRecordDetailPage)에서도
// 이 순서를 그대로 따른다. 단, 어르신 전용 UI(음성으로 질문하기, 바로
// 납부하기/납부 방법 보기 결제 버튼)는 그 파일의 결정대로 뺀다.
// 2026-09-01(2차) — 사용자가 "완전히 똑같게 말고 조금 요약해서" 요청 —
// Senior와 카드 구성/내용은 그대로 두되, "해야 할 일"/"상세 정보" 두
// 카드는 기본 접힘으로 시작한다(Senior는 기본 펼침). 보호자는 위험도/AI
// 요약만 먼저 보고, 필요할 때만 펼쳐서 더 보면 된다.
function guardianAnalysisDetailBody(tone) {
  const cls = "rsl-" + tone;
  const label = { safe: "안심", caution: "주의", dangerous: "위험" }[tone];
  const icon = { safe: "verified", caution: "error", dangerous: "warning" }[tone];
  const isDoc = tone === "safe";
  return `
  <div class="${cls}">
    <div class="rsl-card rsl-risk-row">
      <div class="rsl-risk-col" style="display:flex;gap:10px;align-items:center">
        <span class="rsl-icon-badge">${T.msi(icon)}</span>
        <div>
          <div class="lbl">위험도</div>
          <div class="rsl-risk-value">${label}</div>
          <div class="rsl-risk-desc">${tone === "safe" ? "문제가 발견되지 않았어요." : "혼자 결정하지 마세요."}</div>
        </div>
      </div>
      <div class="divider"></div>
      <div class="rsl-risk-col">
        <div class="lbl">신뢰도 ⓘ</div>
        <div class="rsl-conf-value">87%</div>
        <div class="rsl-stars">${[1, 1, 1, 1, 0].map((on) => `<span class="msi ${on ? "on" : "off"}">star</span>`).join("")}</div>
        <div class="rsl-risk-desc">AI 분석의 신뢰도예요.</div>
      </div>
    </div>

    <div class="rsl-card rsl-info-grid">
      <div class="col"><div class="lbl">분석 날짜</div><div class="val">2026.08.18<br>오후 2:12</div></div>
      <div class="vd"></div>
      <div class="col"><div class="lbl">${isDoc ? "문서 종류" : "발신 번호"}</div><div class="val">${isDoc ? "전기요금 고지서<br>(한국전력)" : "010-****-2231<br>(발신번호 미상)"}</div></div>
      <div class="vd"></div>
      <div class="col"><div class="lbl">${isDoc ? "납부 기한" : "위험 유형"}</div><div class="val">${isDoc ? "2026.08.25<br>D-1일" : "금융/개인정보<br>요구"}</div></div>
    </div>

    <div class="rsl-card">
      <div class="hd"><span class="ttl">AI 요약</span></div>
      <p class="rsl-summary">${isDoc ? "이번 달 요금은 <b>87,500원</b>으로 지난달보다 <b>5,200원</b> 감소했어요." : "고객님 명의로 계좌가 개설됐다며 금융 정보를 요구하는 <b>보이스피싱형 문자</b>예요."}</p>
      <div class="rsl-bullets">
        ${isDoc
          ? `<div class="rsl-bullet">${T.msi("check_circle")}사용량은 12% 감소했어요.</div><div class="rsl-bullet">${T.msi("check_circle")}전기 사용 패턴은 안정적이에요.</div>`
          : `<div class="rsl-bullet">${T.msi("check_circle")}발신번호가 등록되지 않은 번호예요.</div><div class="rsl-bullet">${T.msi("check_circle")}링크를 누르거나 회신하지 않는 게 안전해요.</div>`}
      </div>
    </div>

    <div class="rsl-card">
      <div class="hd" style="cursor:pointer" onclick="const c=this.nextElementSibling;const open=c.style.display!=='none';c.style.display=open?'none':'block';this.querySelector('.msi').textContent=open?'expand_more':'expand_less'"><span class="ttl">아버님 화면에 뜬 해야 할 일</span>${T.msi("expand_more", "chev")}</div>
      <div style="display:none">
        ${isDoc
          ? `<label class="rsl-check-row"><input type="checkbox" checked disabled />납부 기한(08.25) 확인하기<span class="pri">중요</span></label><label class="rsl-check-row"><input type="checkbox" disabled />고지 금액 확인 후 납부하기</label>`
          : `<label class="rsl-check-row"><input type="checkbox" disabled />모르는 링크나 전화는 누르지 않기<span class="pri">중요</span></label><label class="rsl-check-row"><input type="checkbox" disabled />의심되면 보호자에게 먼저 물어보기</label>`}
      </div>
    </div>

    <div class="rsl-card">
      <div class="hd" style="cursor:pointer" onclick="const c=this.nextElementSibling;const open=c.style.display!=='none';c.style.display=open?'none':'block';this.querySelector('.msi').textContent=open?'expand_more':'expand_less'"><span class="ttl">상세 정보</span>${T.msi("expand_more", "chev")}</div>
      <div style="display:none">
        <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">신뢰도</span><span class="body" style="font-weight:700">87%</span></div>
        <div class="body-sm" style="padding-top:8px">원문</div>
        <p class="body-sm" style="margin-top:2px">${isDoc ? "한국전력공사 - 2026년 8월 전기요금 87,500원, 납부기한 8월 25일까지..." : "[Web발신] 고객님 명의로 개설된 계좌가 확인되어 금융감독원에서 확인이 필요합니다. 아래 링크를 눌러..."}</p>
      </div>
    </div>
  </div>`;
}

G("records-detail", "기록", "기록 상세 (위험/확인 완료)", "78, 79, 80", "기록 상세 + 확인 상태.",
  "Senior 상세 화면(analysisResultBody)과 렌더를 공유해 \"시니어가 본 분석 결과를 보호자도 그대로 본다\"를 실제로 보여준다. Guardian은 어르신 전용 UI(음성 질문, 결제 버튼) 대신 조치 버튼(알림 재전송 등)을 붙인다.",
  "확인 여부 배지 + 원문 보기.", ["안전", "위험", "확인완료"], (ctx, state) => {
    const tone = state === "안전" ? "safe" : "dangerous";
    return `
  ${T.topBar("기록 상세")}
  <div class="scr">
    ${T.alertCard(tone, tone === "dangerous" ? "위험해요" : "안전한 문서예요", tone === "dangerous" ? "금전이나 개인정보를 요구하고 있어요." : "특별히 위험한 내용은 없어요.")}
    <div style="height:16px"></div>
    ${guardianAnalysisDetailBody(tone)}
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
