// 2026-08-29 — 사용자 명시: 이 파일(ui-prototype 전체)에서 "죽은 버튼"을
// 고치려고 넣은 vanilla onclick 트릭(예: 차단하기/공유하기 버튼이 문구만
// 바뀌고 disabled되는 것, "현재 내 지역 입력하기"가 그냥 입력칸을 채우는
// 것, 납부 방법 카드에 적힌 가상 계좌번호, 아코디언 펼치기/접기)은 전부
// 발표·리뷰용 프로토타입 화면이 "눌러도 반응 없는 죽은 버튼"처럼 보이지
// 않게 하기 위한 겉모습 흉내일 뿐이다 — 실제 결제/차단/공유/위치 API 연동도
// 아니고, 실제 Flutter 앱(apps/senior)이 이렇게 동작해야 한다는 스펙도
// 아니다. 나중에 이 화면들을 실제로 구현할 때 이 트릭 코드나 여기 적힌
// mock 문구·번호를 그대로 옮기지 말 것 — 진짜 요구사항 분석(app-analysis
// skill)을 거쳐 실제 API/도메인 로직으로 새로 설계해야 한다.
// ---------------------------------------------------------------------
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
// 2026-08-27 — auth-login/auth-phone/onboard-settings/onboard-profile/
// qr-generate/onboard-guardian 6개는 사용자 제공 레퍼런스("온담 최종 디자인
// - 초기 설정 화면")를 그대로 재현한다(문구/필드/버튼 순서 동일). 로고는
// 아이콘이 아니라 실제 제공된 이미지(ONDAM_LOGO_DATA_URI)를 쓴다.
S("auth-login", "인증", "로그인", "1", "재방문 사용자의 첫 진입점 — 앱 소개 + 단일 CTA.",
  "사용자 제공 레퍼런스 그대로 — 로고 이미지 + 단일 CTA.",
  "선택지를 1개(온담 시작하기)만 두어 고민 없이 다음으로 넘어가게 함.", null, (ctx) => `
  <div class="scr center">
    <img src="${ONDAM_LOGO_DATA_URI}" alt="온담" style="width:120px;height:120px;object-fit:contain" />
    <h1 class="h-display" style="margin-top:16px">온담</h1>
    <p class="body-sm" style="margin-bottom:32px">어르신을 위한 안심 생활 비서</p>
    ${T.button("온담 시작하기", { nav: "senior.auth-phone", large: true })}
  </div>`);

S("auth-phone", "인증", "전화번호 입력", "2", "실제 코드의 phone_input_page — 전화번호+비밀번호를 한 화면에서 입력 + 소셜로그인/게스트 진입.",
  "사용자 제공 레퍼런스 그대로 — 휴대폰 번호 + 비밀번호 필드를 한 화면에. " +
  "2026-08-29 — 사용자 요청으로 Easy 앱의 로그인 화면(easy.auth-login)에 있던 소셜로그인/게스트 " +
  "진입을 이 화면 아래에 추가. 화면을 2개(auth-login 로고→auth-phone 입력)로 나눈 레퍼런스 재현 " +
  "결정 자체는 유지 — auth-login은 그대로 두고 이 화면 하단에만 덧붙였다.",
  "전화번호/비밀번호를 한 화면에 둬 화면 전환 없이 로그인·최초 설정을 모두 처리(phone_input_page.dart와 동일 구조). 소셜로그인·게스트는 전부 온보딩(설정 단계)으로 이어진다.", null, (ctx) => `
  <div class="scr">
    <h1 class="h1" style="margin-top:24px">휴대폰 번호로<br>시작하기</h1>
    <p class="body-sm" style="margin-bottom:24px">휴대폰 번호와 비밀번호를 입력해주세요.</p>
    <div class="field" style="margin-bottom:16px"><label>휴대폰 번호</label><input type="tel" value="010-0000-0000" readonly /></div>
    <div class="field"><label>비밀번호</label><input type="password" placeholder="4자리 숫자" readonly /></div>
    <div style="margin-top:28px">${T.button("설정하러 가기", { nav: "senior.onboard-settings", large: true })}</div>
    <div class="or-div">또는</div>
    <button class="social-btn google" data-nav="senior.onboard-settings"><svg width="18" height="18" viewBox="0 0 18 18"><path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.9c1.7-1.57 2.7-3.88 2.7-6.62z"/><path fill="#34A853" d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.9-2.26c-.81.54-1.85.86-3.06.86-2.35 0-4.34-1.59-5.05-3.72H.96v2.33A9 9 0 0 0 9 18z"/><path fill="#FBBC05" d="M3.95 10.7A5.4 5.4 0 0 1 3.67 9c0-.59.1-1.16.28-1.7V4.97H.96A9 9 0 0 0 0 9c0 1.45.35 2.83.96 4.03l2.99-2.33z"/><path fill="#EA4335" d="M9 3.58c1.32 0 2.51.46 3.44 1.35l2.58-2.58C13.46.89 11.43 0 9 0A9 9 0 0 0 .96 4.97l2.99 2.33C4.66 5.17 6.65 3.58 9 3.58z"/></svg>구글 로그인</button>
    <button class="social-btn naver" data-nav="senior.onboard-settings"><span class="badge">N</span>네이버 로그인</button>
    <button class="social-btn kakao" data-nav="senior.onboard-settings"><span class="badge">TALK</span>카카오 로그인</button>
    <button class="btn ghost" data-nav="senior.onboard-settings" style="text-decoration:underline;margin-top:6px">회원가입 없이 사용하기</button>
  </div>`);

// 2026-08-27 — "PIN 입력"/"PIN 설정"/"로그인 오류"/"계정 생성·확인" 삭제.
// auth-phone이 전화번호+비밀번호를 한 화면에서 처리(사용자 제공 레퍼런스)
// 하게 되면서 인증 카테고리는 로그인/전화번호 입력 2개만 남는다.

// ---------- Onboarding ----------
// 2026-08-27 — 사용자 제공 레퍼런스(환영 → 설정 → 완료 3단계 구성)를
// "참고"해 재구성하되, 그대로 베끼지 않았다: 색은 레퍼런스의 그린이 아니라
// 우리 Modern Care 토큰의 primary 블루를 쓰고("완료" 원만 success 그린 —
// 브랜드색과 별개인 의미색), 2단계는 실제 코드
// (`accessibility_settings_form.dart` + `onboarding_flow_page.dart`
// `_AccessibilityStep`)에 이미 있는 글자 크기(보통/크게/아주 크게 — "작게"는
// 실제 앱에 없다)+음성 안내+언어 설정을 전부 담아, 레퍼런스에 없던 기존
// 기능을 누락시키지 않았다.
// 2026-08-29 — 사용자 요청으로 "환영 (1/3)" 온보딩 1단계 화면 삭제. auth-phone
// →(바로) onboard-settings로 이어지며, 온보딩은 이제 설정→내정보→QR→보호자
// 연결요청→완료 흐름이다.
S("onboard-settings", "온보딩", "화면/음성/언어 설정", "8,9", "온보딩 2단계 — 글자 크기 + 음성 안내 + 언어, 실제 코드(AccessibilitySettingsForm + 언어)와 동일한 3항목, 사용자 제공 레퍼런스에서는 한 화면에 결합.",
  "사용자 제공 레퍼런스 그대로 — 3항목을 한 화면에, 헤드라인 '몇 가지만 정해주세요'.",
  "한 화면에 3항목을 다 넣는 대신, 카드 사이 여백을 넉넉히 둬서 섹션 구분이 스크롤 중에도 명확하게. " +
  "2026-08-29 — 사용자 요청(\"없는 기능 추가\")으로 음성 안내 토글/속도 칩/언어 칩에 실제 클릭 반응을 " +
  "추가했다. 이 화면의 글자크기 선택은 이미 리뷰 도구의 state(entry.states)를 쓰는데, 한 화면에 " +
  "state 슬롯은 하나뿐이라 나머지 두 컨트롤에 같은 방식을 쓰면 글자크기 상태와 충돌한다 — 그래서 이 " +
  "셋은 리뷰 도구의 재렌더 시스템을 거치지 않는 순수 vanilla onclick(클릭한 요소만 즉시 active 전환)으로 " +
  "처리했다. 화면을 벗어나면(재렌더) 초기값으로 돌아가지만, 실제 앱과 동일한 라디오 그룹 동작은 보여준다.", ["보통", "크게", "아주 크게"], (ctx, state) => {
    const sizes = { 보통: 22, 크게: 28, "아주 크게": 34 };
    const descs = { 보통: "가장 많이 선택해요.", 크게: "더 크게 보실 수 있어요.", "아주 크게": "가장 크게 보여드려요." };
    const zoom = { 보통: 1, 크게: 1.15, "아주 크게": 1.3 }[state];
    return `
  <div class="scr" style="zoom:${zoom}">
    <h1 class="h1" style="margin-top:8px">몇 가지만<br>정해주세요</h1>
    <p class="body-sm" style="margin:6px 0 0">편하게 사용하실 수 있도록 먼저 설정할게요</p>

    <div class="section-title" style="margin-top:24px">글자 크기</div>
    <div class="stack md">
      ${["보통", "크게", "아주 크게"].map((s) => `
        <button class="textsize-option ${s === state ? "active" : ""}" data-state="${s}">
          ${s === state ? `<span class="chk">${T.msi("check")}</span>` : `<span style="width:22px"></span>`}
          <span class="txt"><span class="tt">${s}</span><span class="ds">${descs[s]}</span></span>
          <span class="sample" style="font-size:${sizes[s]}px">A</span>
        </button>`).join("")}
    </div>

    <div class="section-title" style="margin-top:28px">음성 안내</div>
    ${T.card(`<div class="row"><div style="flex:1"><div class="h-title">음성으로 안내해드려요</div><div class="body-sm">화면을 읽어드려요</div></div><button class="toggle on" onclick="this.classList.toggle('on')"></button></div>`)}

    <div class="section-title" style="margin-top:28px">음성 안내 속도</div>
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:8px" onclick="const b=event.target.closest('.chip');if(!b)return;this.querySelectorAll('.chip').forEach(c=>c.classList.remove('active'));b.classList.add('active')">
      ${["1배", "1.2배", "1.5배", "2배"].map((v) => `<button class="chip ${v === "1배" ? "active" : ""}" style="width:100%;justify-content:center">${v}</button>`).join("")}
    </div>

    <div class="section-title" style="margin-top:28px">언어 설정</div>
    <div class="stack" style="gap:10px" onclick="const b=event.target.closest('.chip');if(!b)return;this.querySelectorAll('.chip').forEach(c=>c.classList.remove('active'));b.classList.add('active')">
      ${["한국어", "English", "日本語", "中文"].map((l) => `<button class="chip ${l === "한국어" ? "active" : ""}" style="width:100%;justify-content:center;min-height:64px;font-size:18px;font-weight:800">${l}</button>`).join("")}
    </div>

    <div style="margin-top:28px">${T.button("내 정보 입력하러 가기", { nav: "senior.onboard-profile", large: true })}</div>
  </div>`; });

// 2026-08-29 — 사용자 요청으로 "Easy Mode" 온보딩 설정 화면 삭제. Easy는
// 이미 별도 앱으로 분리돼 있어(2026-08-27) 이 화면은 애초에 어느 흐름에도
//연결돼 있지 않은 채였다.
S("onboard-profile", "온보딩", "내 정보", "11", "이름/성별/나이/지역 정보 입력.",
  "사용자 제공 레퍼런스 그대로 — 이름/나이/지역 3필드 + 지역 입력·보호자 등록 두 CTA. " +
  "2026-08-29 — 사용자 요청으로 Easy 앱의 onboard-profile에 있던 \"성별\" 필드를 이름 아래에 추가. " +
  "레퍼런스에 없던 필드지만 Easy에는 있고, 실제 맞춤 정보(연령대·성별 맞춤 혜택 등)에 쓰이므로 이식.",
  "필수 필드만, 나머지는 나중에 설정에서. 성별은 Senior 전역에서 이미 쓰는 chip 버튼(2지선다)으로. " +
  "2026-08-29 — 사용자 요청(\"없는 기능 추가\")으로 성별 chip에 클릭 반응 추가(vanilla onclick — " +
  "이유는 onboard-settings와 동일, 이 화면은 별도 state 슬롯이 없다). \"현재 내 지역 입력하기\"는 " +
  "nav도 onclick도 전혀 없어 눌러도 아무 일도 안 일어나던 완전히 죽은 버튼이었던 것을 발견 — 실제 " +
  "위치 API 연동은 프로토타입 범위 밖이라, 누르면 위치를 확인했다는 걸 버튼 자체가 보여주는 확인 " +
  "상태로 바꾼다(문구·아이콘 교체 + 비활성화).", null, (ctx) => `
  <div class="scr">
    <h1 class="h1" style="margin-top:24px">내 정보</h1>
    <div class="field" style="margin:20px 0 16px"><label>이름</label><input value="" placeholder="" readonly /></div>
    <div class="field" style="margin-bottom:16px">
      <label>성별</label>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px" onclick="const b=event.target.closest('.chip');if(!b)return;this.querySelectorAll('.chip').forEach(c=>c.classList.remove('active'));b.classList.add('active')">
        <button class="chip active" style="width:100%;justify-content:center">남성</button>
        <button class="chip" style="width:100%;justify-content:center">여성</button>
      </div>
    </div>
    <div class="field" style="margin-bottom:16px"><label>나이</label><input value="" placeholder="" readonly /></div>
    <div class="field"><label>지역</label><input id="profileRegionInput" value="" placeholder="" readonly /></div>
    <div class="stack" style="margin-top:28px">
      <button class="btn secondary large" onclick="document.getElementById('profileRegionInput').value='${ONDAM_DATA.seniorSelf.region}';this.querySelector('.lbltxt').textContent='현재 위치로 확인했어요';this.disabled=true">${T.msi("my_location")}<span class="lbltxt">현재 내 지역 입력하기</span></button>
      ${T.button("보호자 등록으로 넘어가기", { nav: "senior.onboard-qr", large: true })}
    </div>
  </div>`);

// 2026-08-27 — 사용자 제공 레퍼런스 5번째 화면("보호자에게 이 QR을
// 보여주세요")이 온보딩 카테고리엔 없어서 추가. 화면 내용 자체는 더보기의
// QR 생성(qr-generate)과 동일하지만, 그 화면은 "새로고침" 버튼만 있고
// 다음 단계로 이어지는 길이 없어(더보기에서 독립적으로 쓰일 땐 문제 없지만
// 온보딩 흐름 중간에 쓰면 다음 단계로 갈 수 없어 막다른 길이 됨) 온보딩
// 전용으로 분리하고 보호자 연결 요청 화면으로 넘어가는 CTA를 추가했다.
S("onboard-qr", "온보딩", "보호자 QR 안내", "11~12 사이", "온보딩 중 보호자 연결용 QR 표시 — 다음 단계(연결 요청 수락/거절)로 이어짐.",
  "사용자 제공 레퍼런스 그대로 — 큰 헤드라인 아래 QR, 스캔 시 요청이 전달됨을 안내(더보기의 QR 생성 화면과 문구 동일).",
  "더보기의 QR 생성 화면은 독립 기능(새로고침만 가능)이라 온보딩 중간 단계로 그대로 재사용하면 다음으로 넘어갈 길이 없어 별도 화면으로 분리.", null, (ctx) => `
  <div class="scr center">
    <h1 class="h1" style="margin-top:8px">보호자에게 이 QR을<br>보여주세요</h1>
    <div style="margin-top:20px">${T.qrBox()}</div>
    <p class="body-sm" style="margin:16px 0 24px">보호자가 QR을 스캔하면<br>연결 요청이 도착합니다</p>
    ${T.button("다음", { nav: "senior.onboard-guardian", large: true })}
  </div>`);

S("onboard-guardian", "온보딩", "보호자 연결 요청", "12", "보호자가 QR을 스캔해 보낸 연결 요청을 수락/거절 — 요청자가 누구인지 바로 보이게.",
  "요청 카드에 실제 요청자(이름/관계/연락처)를 보여줘야 실수로 모르는 사람을 수락하지 않음.",
  "아바타(이니셜)+이름+관계를 한 줄로, 연락처는 보조 정보로 흐리게 — 카드 하나에 판단 정보를 전부 담음.", null, (ctx) => `
  <div class="scr center">
    <h1 class="h1" style="margin-top:8px">보호자가 연결 요청을<br>보냈어요</h1>
    <div style="width:100%;margin-top:24px">
      ${T.card(`
        <div class="row" style="gap:12px">
          <div style="width:46px;height:46px;border-radius:50%;background:var(--primary-soft);color:var(--primary);display:flex;align-items:center;justify-content:center;font-size:17px;font-weight:800;flex:none">김</div>
          <div style="flex:1;min-width:0">
            <div class="h-title">김수민</div>
            <div class="body-sm">아들 · 010-****-5678</div>
          </div>
        </div>
      `)}
    </div>
    <div class="row" style="width:100%;gap:10px;margin-top:16px">
      <button class="btn" style="flex:1" data-nav="senior.onboard-complete">수락</button>
      <button class="btn secondary" style="flex:1" data-nav="senior.onboard-complete">거절</button>
    </div>
  </div>`);

// 2026-08-27 — "온보딩 완료" 삭제하고 이 화면(컨페티 체크)이 흐름의 마지막
// 단계를 맡는다. 로그인→전화번호→설정→내정보→QR→보호자연결요청 다음 도착점
// — 온보딩 카테고리에서도 실제로 맨 마지막에 오도록 등록 순서를 옮겼다.
S("onboard-complete", "온보딩", "설정 완료", "13", "온보딩 마지막 단계 — 완료 축하 화면, 바로 홈으로 진입.",
  "컨페티가 흩날리는 큰 체크 원으로 마무리해 설정 과정에 긍정적인 인상을 남김.",
  "요약 카드 없이 체크 아이콘 하나로 완료를 직관적으로 전달, CTA 하나로 바로 홈 진입.", null, (ctx) => `
  <div class="scr center">
    <div class="onb-illus done">
      <span class="confetti c1"></span><span class="confetti c2"></span><span class="confetti c3"></span><span class="confetti c4"></span>
      ${T.msi("check")}
    </div>
    <h1 class="h1" style="margin-top:28px">설정 완료!</h1>
    <p class="body-sm" style="margin-bottom:0">온담을 편하게 이용해보세요</p>
    <div style="width:100%;margin-top:28px">${T.button("온담 시작하기", { nav: "senior.home", large: true })}</div>
  </div>`);

// ---------- Home ----------
// 2026-08-27 — 사용자 요청으로 정직한 빈 상태를 나이/성별/지역 매칭 혜택
// 목록으로 교체. 각 카드에 매칭 근거 태그를 붙여 "왜 나에게 이게 보이는지"를
// 함께 전달(개인정보 기반 추천은 근거를 숨기지 않는다). 실제 구현 시에는
// domain/data 계층(혜택 API)이 필요 — 지금은 mock.
S("info", "홈", "정보 (맞춤 혜택)", "요청 목록 외 — 실제 코드 info_tab_page.dart 대응", "탭 화면 — 나이/성별/지역 조건에 맞는 복지 혜택·정보 안내.",
  "추천 이유를 태그로 함께 보여줘 신뢰를 얻는다(어떤 조건 때문에 이 혜택이 보이는지).",
  "빈 상태 대신 맞춤 혜택 카드 목록으로 변경(2026-08-27). 실제 반영 시 혜택 데이터 소스가 새로 필요.", null, (ctx) => `
  ${T.topBar("정보", { back: false, flushLeft: true })}
  <div class="scr">
    <div class="body-sm" style="margin-bottom:16px">${ONDAM_DATA.seniorSelf.name}님을 위한 맞춤 정보예요</div>
    <div class="stack md">
      ${ONDAM_DATA.benefits.map((b) => T.card(`
        <div class="row" style="align-items:flex-start;gap:14px">
          ${T.iconBadge(b.icon, "primary")}
          <div style="flex:1">
            <div class="h-title" style="font-size:16px;margin-bottom:4px">${b.title}</div>
            <div class="body-sm" style="margin-bottom:8px">${b.desc}</div>
            <span class="tag-pill">${b.tag}</span>
          </div>
        </div>`)).join("")}
    </div>
  </div>
  ${T.bottomNavSenior("senior.info")}`);

// 2026-08-27 — Claude 아티팩트("ONDAM Modern Care") 시안 이식: 긴급 도움을
// 그리드 밖 별도 카드가 아니라 4번째 그리드 카드로 넣되 아이콘만 danger
// 톤으로 구분(Before/After #4), "쉬운 모드" 토글은 박스 없이 텍스트+스위치
// 한 줄, 오늘의 일정 섹션을 추가(최근 기록 대신).
S("home", "홈", "홈", "14, 15", "핵심 기능 진입점 + 긴급 도움 + 오늘의 일정.",
  "Claude 아티팩트 시안(Modern Care) 그대로 이식 + 2026-08-27 쉬운 모드를 별도 앱으로 재설계.",
  "그리드 카드 + 오늘의 일정, 쉬운모드 토글은 카드형으로 상단에 노출(발견 유도). " +
  "2026-08-27(3차) — 쉬운 모드가 이 화면의 상태 전환이 아니라 ONDAM 2.0 아래 Senior/Guardian과 같은 " +
  "층위의 별도 앱(Easy)으로 분리됨에 따라, 이 토글은 이제 easy.home으로 진입하는 링크다 — 실제 " +
  "Flutter 코드에서는 여전히 이 화면의 설정 토글 하나이며, 프로토타입 도구에서만 검토 편의를 위해 " +
  "별도 앱으로 나눠 보여준다. " +
  "2026-08-29(2차) — 사용자 요청으로 3번째 카드를 \"경로당 찾기\"에서 \"공공시설 찾기\"로 넓히고(경로당은 " +
  "공공시설의 한 종류), 오늘의 일정 항목도 함께 맞춤. 긴급 도움은 하단 네비 도움 탭을 되돌리면서 " +
  "다시 이 화면의 3번째 카드 아래 별도 버튼(danger 톤)으로 옮겼다.", null, (ctx) => {
    const features = [
      { icon: "document_scanner", label: "문서 읽기", sub: "사진으로 문서를 읽어드려요", nav: "senior.doc-start" },
      { icon: "sms", label: "문자 확인", sub: "문자를 읽어주고 쉽게 알려드려요", nav: "senior.msg-list" },
      { icon: "place", label: "공공시설 찾기", sub: "주변 공공시설을 찾아보세요", nav: "senior.welfare-search" },
    ];
    const today = [
      { time: "10:00", title: "공공시설 이용 프로그램", loc: "행복 복지관" },
      { time: "14:30", title: "정형외과 진료", loc: "온담정형외과" },
    ];
    return `
  <div class="scr flush" data-app="senior" data-easy="false">
    <div class="scr">
      <div class="home-greeting-row">
        <div class="home-greeting">
          <div class="h1">${ONDAM_DATA.seniorSelf.name}님, 안녕하세요!</div>
          <div class="body-sm">오늘도 편안하고 안전한 하루 되세요</div>
        </div>
        <button class="voice-fab-inline" data-nav="senior.voice" aria-label="음성 비서">${T.msi("mic")}</button>
      </div>
      <div class="row" style="padding-bottom:14px;margin-bottom:14px;border-bottom:1px solid var(--divider)">
        <div style="flex:1">
          <div class="h-title">쉬운 모드</div>
          <div class="body-sm">더 크고 단순한 화면으로 보기</div>
        </div>
        <button class="toggle" data-nav="easy.home"></button>
      </div>
      <div class="feature-grid cols-1">
        ${features.map((f) => `<div class="feature-card row" data-nav="${f.nav}">${T.iconBadge(f.icon, "primary", "lg")}<div class="txt"><span class="lbl">${f.label}</span><span class="sub">${f.sub}</span></div>${T.msi("chevron_right", "chev")}</div>`).join("")}
        <div class="feature-card row" data-nav="senior.emergency">${T.iconBadgeTint("crisis_alert", "danger", "lg")}<div class="txt"><span class="lbl">긴급 도움 (SOS)</span><span class="sub">위급할 때 빠르게 도움을 요청해요</span></div>${T.msi("chevron_right", "chev")}</div>
      </div>
      <div class="row" style="margin-top:24px;margin-bottom:8px">${T.msi("calendar_today", "cal-icon")}<div class="section-title" style="margin:0">오늘의 일정</div></div>
      <div class="stack">
        ${today.map((t) => T.card(`<div class="today-row"><span class="time">${t.time}</span><div class="txt"><div class="ttl">${t.title}</div><div class="loc">${T.msi("place")}${t.loc}</div></div></div>`)).join("")}
      </div>
    </div>
  </div>
  ${T.bottomNavSenior("senior.home")}`; });

// 2026-08-27 — 홈 카테고리 4개 검토: 상단에 emergency 톤 아이콘 배지를 더해
// "위급 상황 화면"이라는 시각적 무게를 헤드라인 앞에 먼저 준다(원래는 텍스트만).
// 2026-08-27 (2차) — 사용자 요청: 시트 뒤로 홈 화면이 그대로 보여야 한다는
// 피드백 반영. senior.home의 render()를 그대로 재사용해 배경으로 깔고(같은
// 화면이라는 확신을 주기 위함 — 새 배경 마크업을 따로 만들지 않는다) 그
// 위에 시트만 덧씌운다. 도움 목록은 보호자 → 119 → 112 순서로 고정.
S("emergency", "홈", "긴급 도움", "16", "긴급 상황 시 도움 요청 시트 — 배경에 홈 화면이 보여야 다른 화면으로 착각하지 않는다.",
  "확인 다이얼로그는 되돌릴 수 없는 행동에만(원칙 7) — 전화 연결 전 1회 확인.",
  "112/119/110/120을 크고 색으로 구분, 취소는 항상 가능. 배경은 홈 화면 재사용 + 스크림으로 어둡게. " +
  "2026-08-29 — 사용자 요청으로 SOS 구성을 보호자 전화/119/112에서 112·119·110·120 4개 공공 긴급/상담 " +
  "번호로 교체. 112(경찰)·119(소방·구급)는 emergency(빨강) 톤으로 다급함을 강조하고, 110(정부민원안내)· " +
  "120(다산콜센터·지역상담)은 secondary 톤으로 구분(생명 관련 긴급 신고와 일반 상담의 무게 차이).", null, (ctx) => `
  <div class="scr flush" data-app="senior" style="position:relative;height:100%;overflow:hidden">
    <div aria-hidden="true">${SCREEN_MAP["senior.home"].render(ctx, "Normal")}</div>
    ${T.sheet(`
      <div style="text-align:center">${T.iconBadge("crisis_alert", "emergency", "lg")}</div>
      <h2 class="h1" style="text-align:center;margin-top:14px">어떤 도움이 필요하세요?</h2>
      <div class="stack md" style="margin-top:16px">
        ${T.button("112 신고하기 (경찰)", { variant: "emergency", icon: "local_police", large: true })}
        ${T.button("119 신고하기 (소방·구급)", { variant: "emergency", icon: "local_fire_department", large: true })}
        ${T.button("110 상담하기 (정부민원안내)", { variant: "secondary", icon: "support_agent", large: true })}
        ${T.button("120 상담하기 (다산콜센터)", { variant: "secondary", icon: "phone_in_talk", large: true })}
        <button class="btn ghost" data-back>취소</button>
      </div>`)}
  </div>`);

// 2026-08-27 — decision에 적혀만 있고 실제 구현은 안 됐던 "마이크 아이콘
// pulsing"을 실제 CSS 애니메이션(퍼져나가는 링 2개)으로 구현.
S("voice", "홈", "음성 비서", "17", "음성 명령 대체 입력 경로.",
  "Google Conversation Design: 단순 조회는 확인 없이 바로 실행.",
  "듣고 있다는 상태를 파형 애니메이션 대신 큰 마이크 아이콘 + 퍼져나가는 링 pulsing으로 단순화. " +
  "2026-08-29 — data-easy=\"true\"가 하드코딩돼 있어 일반 모드에서도 [data-easy=\"true\"] .icon-badge " +
  "규칙(2px 검은 테두리)이 적용되던 버그 수정 — 사용자가 \"마이크 겉의 검은 테두리\"로 지적한 원인. " +
  "다른 화면들처럼 data-easy=\"false\"로 고정.", null, (ctx) => `
  <div class="scr center" data-app="senior" data-easy="false">
    <div class="voice-listen"><span class="ring"></span><span class="ring r2"></span><span class="badge">${T.iconBadge("mic", "primary", "lg")}</span></div>
    <h2 class="h1" style="margin-top:16px">듣고 있어요</h2>
    <p class="body">"문서를 촬영해줘"처럼<br>말씀해보세요</p>
    <button class="btn ghost" data-back style="margin-top:20px">닫기</button>
  </div>`);

// ---------- Document ----------
S("doc-start", "문서 분석", "문서 분석 시작", "18", "문서 촬영 진입 안내.",
  "카메라 진입 전 무엇을 촬영하면 되는지 1문장 안내(원칙 4). " +
  "2026-08-29 — 사용자 요청으로 Easy 앱의 doc-start 구조(촬영하기/불러오기 전체너비 버튼 2개 + 확인 팁 " +
  "카드)를 완화해서 이식: Easy는 easy-btn(굵은 outline)을 쓰지만 여기서는 Senior가 원래 쓰던 " +
  "T.button/T.card 컴포넌트 그대로 사용해 톤을 낮췄다. " +
  "2026-08-29(2차) — 사용자 요청으로 \"음성 안내 다시 듣기\" 버튼 삭제.",
  "고지서 예시 아이콘 대신 촬영하기/불러오기 두 선택지를 바로 제시 + 팁 카드로 정확도 안내.", null, (ctx) => `
  ${T.topBar("문서 분석")}
  <div class="scr">
    <div class="stack md" style="margin-bottom:var(--sp-lg)">
      ${T.button("사진 촬영하기", { variant: "accent", nav: "senior.doc-camera", large: true, icon: "photo_camera" })}
      ${T.button("사진 불러오기", { variant: "secondary", nav: "senior.doc-camera", large: true, icon: "photo_library" })}
    </div>
    ${T.card(`<div class="h-title" style="margin-bottom:8px">${T.msi("info")} 꼭 확인해 주세요!</div><div class="body-sm" style="line-height:1.6">· 문서의 글자가 선명하게 보이도록 촬영해 주세요<br>· 빛 반사가 적은 밝은 곳에서 촬영하면 더 정확해요</div>`)}
  </div>`);

S("doc-camera", "문서 분석", "카메라", "19", "실제 촬영 화면.",
  "카메라는 최소 UI — 셔터만 크게, 플래시는 아이콘+텍스트 병행(기존 결정 유지). " +
  "2026-08-29 — 사용자 요청으로 \"문서를 화면 안에 맞춰주세요\" 안내 문구를 프레임 중앙 아래가 아니라 " +
  "상단 X(닫기) 버튼 옆으로 이동(제목 자리를 안내 문구가 대신함) + 플래시 버튼에 \"플래시\" 라벨을 " +
  "병기해 아이콘만으로 알기 어려웠던 것을 보완 + 셔터가 doc-captured(삭제됨) 대신 doc-multi로 바로 이어짐.",
  "셔터 버튼 80px 이상, 화면 대부분을 프리뷰가 차지. 2026-08-27: 안내 문구만 떠 있어 뭘 맞춰야 할지 막막했던 걸 점선 프레임 가이드로 보완, 셔터 링은 앱 accent 색(--accent, Senior CTA 색과 동일)으로 브랜드 톤 유지, 플래시 버튼은 44px 터치 영역 확보.", null, (ctx) => `
  <div class="scr flush" style="background:#111;min-height:100%;display:flex;flex-direction:column;color:#fff">
    <div class="top-bar" style="color:#fff"><button class="back" style="color:#fff" data-back>${T.msi("close")}</button><h1 style="color:#fff;font-size:14px;font-weight:600">문서를 화면 안에 맞춰주세요</h1><button class="right-action" style="color:#fff;display:flex;align-items:center;gap:3px;flex:none">${T.msi("flash_off")}<span style="font-size:11px">플래시</span></button></div>
    <div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:24px">
      <div style="width:100%;max-width:280px;aspect-ratio:3/4;border:2px dashed rgba(255,255,255,.5);border-radius:var(--r-lg)"></div>
    </div>
    <div style="display:flex;justify-content:center;padding:24px"><button data-nav="senior.doc-multi" style="width:76px;height:76px;border-radius:50%;background:#fff;border:6px solid var(--accent)"></button></div>
  </div>`);

// 2026-08-29 — 사용자 요청으로 "촬영 완료" 화면 삭제, doc-camera 셔터가
// doc-multi(다중 문서 진행)로 바로 이어지도록 변경 — 단일/복수 촬영 모두
// doc-multi 하나가 검토+추가촬영+분석시작을 담당한다.
S("doc-analyzing", "문서 분석", "분석 중", "21", "AI 분석 진행 상태.",
  "막연한 스피너보다 진행률(%)을 보여줘 얼마나 남았는지 가늠할 수 있게(2026-08-27 사용자 제공 시안으로 교체 — 기존 스피너+문구 방식 대체).",
  "\"무슨 일이 일어나고 있는지\" 문장으로 불안감 감소. 진행률 숫자를 크게 강조 + 다중 문서일 땐 몇 번째 문서인지 하단에 작게(예시: 2장 중 1번째).", null, (ctx) => `
  <div class="scr center">
    <div style="font-size:40px;font-weight:800;color:var(--primary);letter-spacing:-.5px">67%</div>
    <div class="confidence-bar" style="width:100%;max-width:260px;margin-top:16px"><i style="width:67%"></i></div>
    <p class="body" style="margin-top:20px;font-weight:700">온담이 열심히 분석하고 있어요</p>
    <p class="body-sm" style="margin-top:4px">1/2 문서 분석 중</p>
  </div>`);

// 2026-08-27 — Claude 아티팩트("ONDAM Modern Care") 시안 이식. 문서 분석과
// 문자 분석이 실제 코드에서 AnalysisResultView 하나를 공유하는 것처럼, 이
// 프로토타입에서도 같은 렌더를 두 곳(doc-result/msg-result)이 재사용한다
// — 상단 "문서 종류" 라벨만 문서/문자에 맞게 바뀐다.
// 2026-08-29 — 사용자 요청("없는 기능 추가")으로 "바로 납부하기"/"납부 방법
// 보기" 버튼에 nav/onclick이 전혀 없어 눌러도 아무 일도 안 일어나던 것을
// 발견해 고쳤다. "바로 납부하기"는 실제 결제 연동은 범위 밖이라 한국전력
// 고객센터 실제 공개 번호(국번없이 123) tel: 링크로, "납부 방법 보기"는
// vanilla onclick으로 계좌이체/가상계좌/자동이체 안내를 펼쳐 보여준다(이
// 함수는 doc-result의 state 슬롯이 이미 안심/주의/위험에 쓰이고 있어 같은
// 방식을 못 씀 — onboard-settings와 같은 이유).
function analysisResultBody(kind, state, confirmNav) {
  const tone = state === "위험" ? "dangerous" : state === "주의" ? "caution" : "safe";
  const cls = "rsl-" + tone;
  const label = { safe: "안심", caution: "주의", dangerous: "위험" }[tone];
  const icon = { safe: "verified", caution: "error", dangerous: "warning" }[tone];
  const isDoc = kind === "doc";
  return `
  <div class="${cls}">
    <div class="rsl-card rsl-risk-row">
      <div class="rsl-risk-col" style="display:flex;gap:10px;align-items:center">
        <span class="rsl-icon-badge">${T.msi(icon)}</span>
        <div>
          <div class="lbl">위험도</div>
          <div class="rsl-risk-value">${label}</div>
          <div class="rsl-risk-desc">${tone === "safe" ? "문제가 발견되지 않았어요." : tone === "caution" ? "확인이 필요해요." : "혼자 결정하지 마세요."}</div>
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
      <div class="col"><div class="lbl">분석 날짜</div><div class="val">2026.08.24<br>오전 10:32</div></div>
      <div class="vd"></div>
      <div class="col"><div class="lbl">${isDoc ? "문서 종류" : "발신 번호"}</div><div class="val">${isDoc ? "전기요금 고지서<br>(한국전력)" : "050-1234-5678<br>(발신번호 미상)"}</div></div>
      <div class="vd"></div>
      <div class="col"><div class="lbl">납부 기한</div><div class="val">2026.08.25<br><span class="val risk" style="display:inline">D-1일</span></div></div>
    </div>

    <div class="rsl-card">
      <div class="hd"><span class="ttl">AI 요약</span></div>
      <p class="rsl-summary">이번 달 요금은 <b>87,500원</b>으로 지난달보다 <b>5,200원</b> 감소했어요.</p>
      <div class="rsl-bullets">
        <div class="rsl-bullet">${T.msi("check_circle")}사용량은 12% 감소했어요.</div>
        <div class="rsl-bullet">${T.msi("check_circle")}전기 사용 패턴은 안정적이에요.</div>
        <div class="rsl-bullet">${T.msi("check_circle")}납부 기한이 하루 남았으니 확인 후 납부하세요.</div>
      </div>
    </div>

    <div class="rsl-card">
      <div class="hd" style="cursor:pointer" onclick="const c=this.nextElementSibling;const open=c.style.display!=='none';c.style.display=open?'none':'block';this.querySelector('.msi').textContent=open?'expand_more':'expand_less'"><span class="ttl">해야 할 일</span>${T.msi("expand_less", "chev")}</div>
      <div>
        <label class="rsl-check-row"><input type="checkbox" checked />납부 기한(08.25) 확인하기<span class="pri">중요</span></label>
        <label class="rsl-check-row"><input type="checkbox" />고지 금액 확인 후 납부하기</label>
        <label class="rsl-check-row"><input type="checkbox" />다음 달 사용량도 확인해보기</label>
        <div class="rsl-btn-row">
          <a class="btn solid-risk" style="flex:1;text-decoration:none" href="tel:123">바로 납부하기</a>
          <button class="btn outline-risk" style="flex:1" onclick="event.stopPropagation();const d=this.closest('.rsl-card').querySelector('.rsl-pay-methods');d.style.display=d.style.display==='none'?'block':'none'">납부 방법 보기</button>
        </div>
        <div class="rsl-pay-methods" style="display:none;margin-top:12px;padding-top:12px;border-top:1px solid var(--divider);font-size:13px;line-height:1.7;color:var(--text-secondary)">
          · 계좌이체: 한국전력 국민은행 123456-78-901234<br>
          · 가상계좌: 자동으로 발급된 본인 명의 가상계좌로 입금<br>
          · 자동이체: 한전ON 앱 또는 국번없이 123에서 신청
        </div>
      </div>
    </div>

    <div class="rsl-card">
      <div class="hd" style="cursor:pointer" onclick="const c=this.nextElementSibling;const open=c.style.display!=='none';c.style.display=open?'none':'block';this.querySelector('.msi').textContent=open?'expand_more':'expand_less'"><span class="ttl">상세 정보</span>${T.msi("expand_less", "chev")}</div>
      <div>
        <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">청구 금액</span><span class="body" style="font-weight:700">87,500원</span></div>
        <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">지난달 대비</span><span class="body" style="font-weight:700;color:var(--success)">-5,200원 (▼5.6%)</span></div>
        <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">사용 기간</span><span class="body" style="font-weight:700">2026.07.21 ~ 08.20</span></div>
        <div class="row between" style="padding:6px 0"><span class="body-sm">고객 번호</span><span class="body" style="font-weight:700">12 3456 7890</span></div>
        <div class="rsl-tip">${T.msi("lightbulb")}<div><div class="t">전기 절약 팁</div><div class="d">에어컨 필터를 주기적으로 청소하면 전기 사용량을 줄일 수 있어요.</div></div></div>
      </div>
    </div>

    <div class="rsl-voice" data-nav="senior.voice">
      <span class="ic">${T.msi("mic")}</span>
      <div><div class="t">이 내용에 대해 질문해보세요</div><div class="d">음성으로 궁금한 점을 물어보세요.</div></div>
      ${T.msi("chevron_right", "chev")}
    </div>

    <button class="rsl-cta" data-nav="${confirmNav}">
      <span class="ic">${T.msi("check")}</span>
      <div><div class="t">확인 완료</div><div class="d">이 분석 결과를 확인하셨나요?</div></div>
    </button>
  </div>`;
}

S("doc-result", "문서 분석", "분석 결과 / 위험 문서 결과", "22, 23", "분석 결과 — 위험도별 표현(Claude 아티팩트 시안 이식, msg-result와 렌더 공유).",
  "색상 단독 금지(원칙 6) — 색+아이콘+텍스트+행동안내 4중 표현. " +
  "2026-08-29 — 사용자 요청으로 Easy 앱의 결과 화면 구조(배지→한 문장 헤드라인→상세)를 완화해서 " +
  "이식: analysisResultBody()는 손대지 말라는 기존 지시(msg-result-real 관련)를 지켜 함수 자체는 " +
  "그대로 두고, 그 위에 한 줄 요약 T.alertCard만 추가했다 — 상세 카드로 내려가기 전에 결론부터 보여준다. " +
  "2026-08-29(2차) — 사용자 요청으로 \"확인 완료\" 중간 화면을 삭제하고 확인 완료 버튼(rsl-cta)이 " +
  "바로 senior.home으로 이동하게 변경.",
  "위험도 색이 화면 전체 강조색이 됨(안심=success/주의=warning/위험=danger).", ["안심", "주의", "위험"], (ctx, state) => {
    const tone = state === "위험" ? "dangerous" : state === "주의" ? "caution" : "safe";
    const headline = { safe: "안심이에요", caution: "주의가 필요해요", dangerous: "위험해요" }[tone];
    const desc = { safe: "문제가 발견되지 않았어요.", caution: "확인이 필요해요.", dangerous: "혼자 결정하지 마세요." }[tone];
    return `
  ${T.topBar("분석 결과", { right: `<button class="right-action" style="display:flex;align-items:center;gap:3px">${T.msi("ios_share")}공유</button>` })}
  <div class="scr">
    ${T.alertCard(tone, headline, desc)}
    <div style="height:16px"></div>
    ${analysisResultBody("doc", state, "senior.home")}
  </div>`; });

// 2026-08-29 — 사용자 요청으로 "확인 완료"/"다시 촬영" 화면 삭제.
// analysisResultBody()의 확인 완료 버튼(rsl-cta)은 이제 senior.home으로
// 바로 이동한다(doc-result 정의부 confirmNav 참고). doc-camera는 이미
// doc-captured/doc-retake를 거치지 않고 doc-multi로 바로 이어진다.
// 2026-08-30 — Senior 내부 일관성 점검: doc-start처럼 stack 안에 쌓인
// 전체너비 버튼 2개는 항상 둘 다 large — 이 화면만 첫 버튼에 large가
// 빠져 둘째 버튼보다 얇게 보이던 것을 맞췄다(guardian-link/qr-generate의
// 단독 CTA도 같은 이유로 동일하게 large 추가).
S("doc-multi", "문서 분석", "다중 문서 진행", "26", "여러 장 촬영 진행 상태.",
  "진행 상태는 숫자+점으로 단순 표시.",
  "\"2장 촬영했어요\" + 추가/완료 두 선택지만. 2026-08-27: 매수 표시에 위험도 배지(riskBadge)를 쓰고 있어 \"안전하게 촬영됨\"처럼 의미가 잘못 읽히던 것을 매수 전용 tag-pill로 교체, 촬영한 페이지를 실감나게 보여주도록 썸네일 자리 추가.", null, (ctx) => `
  ${T.topBar("문서 촬영")}
  <div class="scr">
    ${T.card(`<div class="row between"><span class="h-title">2장 촬영했어요</span><span class="tag-pill">2장</span></div>`)}
    <div class="row" style="gap:10px;margin-top:12px">
      ${[1, 2].map(() => `<div style="flex:1;aspect-ratio:3/4;background:var(--surface);border-radius:var(--r-md);display:flex;align-items:center;justify-content:center">${T.iconBadgeTint("description", "primary")}</div>`).join("")}
    </div>
    <div class="stack" style="margin-top:20px">
      ${T.button("한 장 더 촬영하기", { variant: "secondary", nav: "senior.doc-camera", icon: "add_a_photo", large: true })}
      ${T.button("분석 시작하기", { variant: "accent", nav: "senior.doc-analyzing", large: true })}
    </div>
  </div>`);

// ---------- Message ----------
// 2026-08-29 — 사용자 요청으로 Easy 앱의 문자 목록 구조(← 홈으로 텍스트 백 +
// 큰 제목 + 2줄 안내문 + 위험도 배지 없이 바로 탭하는 목록)를 그대로 Senior로
// 이식. Easy 화면은 data-easy="true" 스코프에서만 굵은 outline이 붙는데(다른
// 화면들과 같은 이유), Senior 컨텍스트(data-easy="false")로 옮기면 그 테두리
// 없이 렌더된다 — 별도 CSS 제거 작업 불필요. 데이터는 Easy의 하드코딩된
// mock 대신 다른 화면(records/stats)과 이미 공유하는 ONDAM_DATA.messages를
// 그대로 쓴다. 목록 항목은 분석 전 상태라 위험도 배지를 보이지 않고, 탭하면
// msg-analyzing으로 바로 이어진다(삭제된 msg-detail 대체).
S("msg-list", "문자 분석", "문자 확인", "27", "문자 분석 진입 — 최근 확인한 문자 목록.",
  "Easy 앱의 msg-list 그대로(별도 CTA 없이 목록 항목을 바로 눌러 분석 시작).",
  "\"홈으로\" 텍스트 백 + 안내문 두 줄 + 위험도 배지 없는 목록(분석 전 상태이므로).", ["불러오는 중", "목록", "빈 목록"], (ctx, state) => `
  <div class="top-bar">
    <button class="back" style="width:auto" data-back>${T.msi("arrow_back")}홈으로</button>
  </div>
  <div class="scr">
    <div class="h1" style="margin-bottom:4px">최근 문자</div>
    <p class="body-sm" style="margin-bottom:var(--sp-lg)">최근 문자를 가져왔어요.<br>확인하고 싶은 문자를 눌러주세요.</p>
    ${state === "불러오는 중" ? T.loadingState() : state === "빈 목록" ? T.emptyState("sms", "아직 확인한 문자가 없어요", "새 문자를 확인해보세요") : `
    <div class="stack msg-list-cards">
      ${ONDAM_DATA.messages.slice(0, 4).map((m) => T.listRow({ leftBadge: T.iconBadgeTint("sms", "primary", "sm"), title: m.preview.slice(0, 16) + "…", sub: m.date, nav: "senior.msg-analyzing" })).join("")}
    </div>`}
  </div>`);

// 2026-08-27 — 사용자 요청으로 문서 분석 중과 같은 진행률 UI로 통일. 문자
// 확인은 문서처럼 여러 장이 아니라 한 건이라 "N/2 문서 분석 중" 같은 개수
// 캡션은 빼고 문구만 문자에 맞게 바꿨다 — 그 외 레이아웃/컴포넌트는 동일.
S("msg-analyzing", "문자 분석", "문자 분석 중", "27~28 사이", "AI 문자 분석 진행 상태.",
  "문서 분석 중과 같은 진행률(%) UI로 통일 — 기존엔 문자 확인 목록에서 바로 결과로 넘어가 분석 중이라는 단계 자체가 없었음.",
  "문서 분석 중과 동일한 레이아웃(퍼센트 + 진행바 + 문구), 문서 개수 캡션만 문자용 문구로 교체.", null, (ctx) => `
  <div class="scr center">
    <div style="font-size:40px;font-weight:800;color:var(--primary);letter-spacing:-.5px">67%</div>
    <div class="confidence-bar" style="width:100%;max-width:260px;margin-top:16px"><i style="width:67%"></i></div>
    <p class="body" style="margin-top:20px;font-weight:700">온담이 열심히 분석하고 있어요</p>
    <p class="body-sm" style="margin-top:4px">문자 내용을 확인하는 중이에요</p>
  </div>`);

// 2026-08-27 — analysisResultBody()는 doc/msg 공용이라 문자 결과에도 전기요금
// 고지서 내용(사용기간/절약팁/청구금액 등)이 그대로 나오는 내용 불일치가 있었음.
// 실제 문자 시나리오(ONDAM_DATA.messages의 m1 — 계좌 도용 사칭 문자)에 맞춘
// 내용으로 채운 화면을 별도로 둔다. 레이아웃/rsl-* CSS는 100% 재사용, 내용
// (발신 번호/위험 유형/체크리스트/상세 정보)만 문자에 맞게 교체.
// 2026-08-29 — 사용자 요청으로 위 불일치 문제의 원인이었던 제네릭 버전
// (analysisResultBody 공유, 고지서 내용이 잘못 섞여 나오던 화면) 삭제 —
// 아래 msgResultBodyReal 기반 화면만 문자 분석 결과로 남긴다.
// 2026-08-29 — 사용자 요청("없는 기능 추가")으로 "이 번호 차단하기"/
// "보호자에게 공유하기" 버튼에도 nav/onclick이 없어 죽어있던 것을 발견 —
// 실제 차단·공유 연동은 범위 밖이라, 눌렀을 때 버튼 자체가 완료 상태로
// 바뀌는 즉시 피드백(문구 교체+비활성화)으로 최소한의 반응을 준다.
function msgResultBodyReal(state, confirmNav) {
  const tone = state === "위험" ? "dangerous" : state === "주의" ? "caution" : "safe";
  const cls = "rsl-" + tone;
  const label = { safe: "안심", caution: "주의", dangerous: "위험" }[tone];
  const icon = { safe: "verified", caution: "error", dangerous: "warning" }[tone];
  return `
  <div class="${cls}">
    <div class="rsl-card rsl-risk-row">
      <div class="rsl-risk-col" style="display:flex;gap:10px;align-items:center">
        <span class="rsl-icon-badge">${T.msi(icon)}</span>
        <div>
          <div class="lbl">위험도</div>
          <div class="rsl-risk-value">${label}</div>
          <div class="rsl-risk-desc">${tone === "safe" ? "문제가 발견되지 않았어요." : tone === "caution" ? "확인이 필요해요." : "혼자 결정하지 마세요."}</div>
        </div>
      </div>
      <div class="divider"></div>
      <div class="rsl-risk-col">
        <div class="lbl">신뢰도 ⓘ</div>
        <div class="rsl-conf-value">94%</div>
        <div class="rsl-stars">${[1, 1, 1, 1, 1].map((on) => `<span class="msi ${on ? "on" : "off"}">star</span>`).join("")}</div>
        <div class="rsl-risk-desc">AI 분석의 신뢰도예요.</div>
      </div>
    </div>

    <div class="rsl-card rsl-info-grid">
      <div class="col"><div class="lbl">분석 날짜</div><div class="val">2026.08.18<br>오후 2:12</div></div>
      <div class="vd"></div>
      <div class="col"><div class="lbl">발신 번호</div><div class="val">010-****-2231<br>(발신번호 도용 의심)</div></div>
      <div class="vd"></div>
      <div class="col"><div class="lbl">위험 유형</div><div class="val"><span class="val risk" style="display:inline">금융·개인정보<br>요구</span></div></div>
    </div>

    <div class="rsl-card">
      <div class="hd"><span class="ttl">AI 요약</span></div>
      <p class="rsl-summary">이 문자는 <b>금융기관을 사칭</b>해 계좌 정보 확인과 <b>이체</b>를 요구하고 있어요.</p>
      <div class="rsl-bullets">
        <div class="rsl-bullet">${T.msi("check_circle")}발신 번호가 기관 대표번호가 아닌 개인 번호예요.</div>
        <div class="rsl-bullet">${T.msi("check_circle")}지금 바로 조치하라며 압박하는 문구가 있어요.</div>
        <div class="rsl-bullet">${T.msi("check_circle")}실제 금융기관은 문자로 계좌 이체를 요구하지 않아요.</div>
      </div>
    </div>

    <div class="rsl-card">
      <div class="hd" style="cursor:pointer" onclick="const c=this.nextElementSibling;const open=c.style.display!=='none';c.style.display=open?'none':'block';this.querySelector('.msi').textContent=open?'expand_more':'expand_less'"><span class="ttl">해야 할 일</span>${T.msi("expand_less", "chev")}</div>
      <div>
        <label class="rsl-check-row"><input type="checkbox" checked />이 번호로 답장하거나 전화하지 않기<span class="pri">중요</span></label>
        <label class="rsl-check-row"><input type="checkbox" checked />문자 속 링크 누르지 않기</label>
        <label class="rsl-check-row"><input type="checkbox" />보호자에게 이 문자 공유하기</label>
        <div class="rsl-btn-row">
          <button class="btn solid-risk" style="flex:1" onclick="event.stopPropagation();this.textContent='차단했어요';this.disabled=true">이 번호 차단하기</button>
          <button class="btn outline-risk" style="flex:1" onclick="event.stopPropagation();this.textContent='전달했어요';this.disabled=true">보호자에게 공유하기</button>
        </div>
      </div>
    </div>

    <div class="rsl-card">
      <div class="hd" style="cursor:pointer" onclick="const c=this.nextElementSibling;const open=c.style.display!=='none';c.style.display=open?'none':'block';this.querySelector('.msi').textContent=open?'expand_more':'expand_less'"><span class="ttl">상세 정보</span>${T.msi("expand_less", "chev")}</div>
      <div>
        <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">수신 시각</span><span class="body" style="font-weight:700">2026.08.18 오후 2:12</span></div>
        <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">발신 번호</span><span class="body" style="font-weight:700">010-****-2231</span></div>
        <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">위험 신호</span><span class="body" style="font-weight:700;color:var(--danger)">3개 발견</span></div>
        <div class="row between" style="padding:6px 0"><span class="body-sm">유사 사례</span><span class="body" style="font-weight:700">최근 7일 12건 신고</span></div>
        <div class="rsl-tip">${T.msi("lightbulb")}<div><div class="t">이런 문자를 받으면</div><div class="d">출처가 불분명한 문자의 링크는 절대 누르지 말고, 의심되면 국번 없이 118(인터넷진흥원)로 확인하세요.</div></div></div>
      </div>
    </div>

    <div class="rsl-voice" data-nav="senior.voice">
      <span class="ic">${T.msi("mic")}</span>
      <div><div class="t">이 내용에 대해 질문해보세요</div><div class="d">음성으로 궁금한 점을 물어보세요.</div></div>
      ${T.msi("chevron_right", "chev")}
    </div>

    <button class="rsl-cta" data-nav="${confirmNav}">
      <span class="ic">${T.msi("check")}</span>
      <div><div class="t">확인 완료</div><div class="d">이 분석 결과를 확인하셨나요?</div></div>
    </button>
  </div>`;
}

S("msg-result-real", "문자 분석", "문자 분석 결과 (실제 문자 내용 버전)", "28, 29, 30", "실제 문자 시나리오(계좌 도용 사칭 문자, ONDAM_DATA.messages m1)에 맞는 내용으로 채운 문자 분석 결과 화면.",
  "색상 단독 금지(원칙 6) — 색+아이콘+텍스트+행동안내 4중 표현.",
  "레이아웃/rsl-* CSS는 doc-result와 동일, 내용만 실제 문자(발신번호/위험 유형/체크리스트/상세 정보)에 맞게 교체. " +
  "2026-08-29 — 사용자 요청으로 \"보호자 알림 안내\" 중간 화면 삭제, 확인 완료 버튼이 doc-result와 " +
  "동일하게 바로 senior.home으로 이동하게 변경.", ["안심", "주의", "위험"], (ctx, state) => `
  ${T.topBar("문자 분석 결과", { right: `<button class="right-action" style="display:flex;align-items:center;gap:3px">${T.msi("ios_share")}공유</button>` })}
  <div class="scr">${msgResultBodyReal(state, "senior.home")}</div>`);

// 2026-08-29 — 사용자 요청으로 "문자 분석 상세"/"보호자 알림 안내" 화면 삭제.
// 문자 목록(msg-list)은 이제 msg-analyzing으로 바로 이어지고, msg-detail이
// 하던 역할(과거 분석 상세 보기)은 records 목록에서 msg-result-real로
// 대체된다(records 정의부 참고).

// ---------- Records ----------
// 2026-08-29 — 사용자 요청: (1) "기록" 타이틀을 화면 맨 왼쪽으로(flushLeft),
// (2) 별도 필터 화면(records-filter) 대신 타이틀 아래에 전체/안전/주의/위험
// 칩을 바로 두기, (3) 기록 상세 화면 삭제 — 문서/문자 기록을 각각 실제
// 결과 화면(doc-result/msg-result-real)으로 바로 연결(r.type으로 분기).
// 필터 칩은 이 화면이 이미 쓰는 상태 변수(state)에 얹는다 — "전체"/"안전"/
// "주의"/"위험"은 로딩/빈기록/오류 분기에 안 걸리므로 그대로 목록이 보이고,
// 칩만 active로 바뀐다(실제 목록 필터링은 프로토타입 범위 밖).
S("records", "기록", "기록 목록", "33", "탭 화면 — 전체 분석 기록.",
  "Guardian과 동일한 위험도 배지 체계 공유(일관성).",
  "기록은 최신순. 2026-08-27: \"최신순\"이라 적어놓고 실제로는 문서 배열 뒤에 문자 배열을 이어붙이기만 해 날짜순이 아니었던 것 → date 기준 내림차순 정렬 추가, 목록 끝과 하단 네비 사이 여백도 추가. " +
  "2026-08-29 — 사용자 요청으로 필터 칩이 실제로 목록을 걸러내게 수정(이전엔 활성 표시만 바뀌고 목록은 " +
  "그대로였음) — 안전/주의/위험은 r.risk와 매칭, 전체는 필터 없음.", ["불러오는 중", "목록", "빈 기록", "오류"], (ctx, state) => {
    const riskFilter = { 안전: "safe", 주의: "caution", 위험: "dangerous" }[state];
    return `
  ${T.topBar("기록", { back: false, flushLeft: true })}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    <div class="chip-row" style="margin-bottom:12px">${["전체", "안전", "주의", "위험"].map((l) => `<button class="chip ${l === state || (l === "전체" && !["안전", "주의", "위험"].includes(state)) ? "active" : ""}" data-state="${l}">${l}</button>`).join("")}</div>
    ${state === "불러오는 중" ? T.loadingState() : state === "오류" ? T.errorState("기록을 불러오지 못했어요", "senior.records") : state === "빈 기록" ? T.emptyState("history", "아직 기록이 없어요", "문서나 문자를 확인하면 여기에 쌓여요") : (() => {
      const rows = [...ONDAM_DATA.documents.filter((d) => d.elderId === "e1"), ...ONDAM_DATA.messages.filter((m) => m.elderId === "e1")]
        .sort((a, b) => b.date.localeCompare(a.date))
        .filter((r) => !riskFilter || r.risk === riskFilter);
      return rows.length === 0 ? T.emptyState("filter_alt", "해당하는 기록이 없어요", "다른 필터를 선택해보세요") : `
    <div class="stack" style="padding:8px 0 24px">
      ${rows.map((r) => T.listRow({ leftBadge: T.iconBadgeTint(r.type ? "description" : "sms", "primary", "sm"), title: r.title || r.preview.slice(0, 18) + "…", sub: r.date, right: T.riskBadge(r.risk), nav: r.type ? "senior.doc-result" : "senior.msg-result-real" })).join("")}
    </div>`; })()}
  </div>
  ${T.bottomNavSenior("senior.records")}`; });

// ---------- Statistics ----------
// 2026-08-29 — 사용자 요청으로 "요금 통계 자세히 보기" 카드(→ stats-fee)를
// 삭제하고 그 내용(월별/연별 토글, 선 그래프, 통계 카드, 최근 고지서 목록)을
// 이 화면에 그대로 병합했다. stats-fee 화면 자체는 카탈로그에 남아있지만
// (검색 가능) 앱 흐름에서는 더 이상 연결되지 않는다.
S("stats-home", "통계", "통계 (월별/연별)", "37, 38, 39, 40, 41", "이번 달 요약 + 월별/연별 요금 추이 + 최근 고지서를 한 화면에.",
  "WWIT 네이버페이 자산 화면 — 요약 카드 → 세부 순.",
  "핵심 숫자(이번 달 요금)를 최상단에, 그래프·통계 카드·최근 고지서는 그 아래 이어서.", ["기본", "빈 상태", "월별", "연별"], (ctx, state) => {
    const isMonthly = state !== "연별";
    const data = isMonthly ? ONDAM_DATA.feeStats.monthly : ONDAM_DATA.feeStats.yearly;
    return `
  ${T.topBar("통계", { back: false, flushLeft: true })}
  <div class="scr flush" style="padding:0 var(--sp-lg) var(--sp-xxl)">
    ${state === "빈 상태" ? T.emptyState("bar_chart", "아직 통계가 없어요", "문서를 촬영하면 요금 통계를 볼 수 있어요") : `
    <div style="padding-top:8px">
      <div class="chip-row">${["월별", "연별"].map((l) => `<button class="chip ${(isMonthly && l === "월별") || (!isMonthly && l === "연별") ? "active" : ""}" data-state="${l}">${l}</button>`).join("")}</div>
      <div style="height:14px"></div>
      ${T.feeHero(isMonthly ? "8월 요금" : "2026년 요금", isMonthly ? 87500 : 1980000, isMonthly ? -12500 : -300000, isMonthly ? "지난달보다" : "작년보다")}
      <div style="height:16px"></div>
      ${T.lineChart(data, isMonthly ? "m" : "y")}
      <div style="height:20px"></div>
      ${T.statGrid([T.statCard("payments", "primary", won(ONDAM_DATA.feeStats.total), "총 금액"), T.statCard("insights", "secondary", won(ONDAM_DATA.feeStats.avg), "평균 금액"), T.statCard("receipt_long", "success", ONDAM_DATA.feeStats.count + "건", "고지서 수")])}
      <div class="section-title" style="margin-top:24px">최근 고지서</div>
      <div class="stack">
        ${ONDAM_DATA.documents.filter((d) => d.elderId === "e1" && d.type === "고지서").map((d) => T.listRow({ leftBadge: T.iconBadgeTint("receipt_long", "primary", "sm"), title: d.title, sub: d.date, right: `<span class="body" style="font-weight:700">${won(d.amount)}</span>`, nav: "senior.stats-detail" })).join("")}
      </div>
    </div>`}
  </div>
  ${T.bottomNavSenior("senior.more")}`; });

S("stats-fee", "통계", "요금 통계 (월별/연별)", "38, 39, 40", "월별·연별 요금 추이.",
  "숫자 요약을 반드시 그래프와 함께(사용자 지정 예시: \"8월 요금 87,500원, 지난달보다 12,500원 적어요\").",
  "그래프만 보여주지 않고 핵심 문장을 카드 최상단에 고정. 2026-08-27: 통계 상세(stats-detail) 화면으로 들어갈 방법이 어디에도 없던 것 → 그래프 아래 최근 고지서 목록을 추가해 개별 고지서를 탭해 상세로 들어갈 수 있게.", ["월별", "연별"], (ctx, state) => {
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
    <div class="section-title" style="margin-top:24px">최근 고지서</div>
    <div class="stack">
      ${ONDAM_DATA.documents.filter((d) => d.elderId === "e1" && d.type === "고지서").map((d) => T.listRow({ leftBadge: T.iconBadgeTint("receipt_long", "primary", "sm"), title: d.title, sub: d.date, right: `<span class="body" style="font-weight:700">${won(d.amount)}</span>`, nav: "senior.stats-detail" })).join("")}
    </div>
  </div>`; });

S("stats-detail", "통계", "통계 상세", "42", "개별 고지서 상세.",
  "원본 항목을 구조화된 표로 나열(현재 코드 AppInfoRow 패턴 유지).",
  "핵심 금액을 상단에 강조 후 세부 항목 나열. " +
  "2026-08-29 — 사용자 요청으로 \"더 상세하게\": 고객번호·사용기간·요금 세부 내역(기본요금/전력량요금/" +
  "부가가치세/전력산업기반기금, 합산하면 총액과 일치)·절약 팁을 추가 — analysisResultBody()의 doc-result " +
  "상세 정보 카드와 같은 수치를 재사용해 화면 간 금액이 어긋나지 않게 했다.", null, (ctx) => `
  ${T.topBar("고지서 상세", { flushLeft: true })}
  <div class="scr">
    ${T.card(`<div class="body-sm">한국전력 전기요금</div><div class="h-display" style="margin-top:4px">87,500원</div><div class="body-sm">2026.08.25 납부 기한</div>`)}
    <div style="height:16px"></div>
    ${T.card(`
      <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">고객 번호</span><span class="body" style="font-weight:700">12 3456 7890</span></div>
      <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">사용 기간</span><span class="body" style="font-weight:700">2026.07.21 ~ 08.20</span></div>
      <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">사용량</span><span class="body" style="font-weight:700">312kWh</span></div>
      <div class="row between" style="padding:6px 0"><span class="body-sm">전월 대비</span><span class="body" style="font-weight:700;color:var(--success)">-12,500원 (▼12.5%)</span></div>
    `)}
    <div style="height:16px"></div>
    ${T.card(`
      <div class="h-title" style="margin-bottom:10px">요금 세부 내역</div>
      <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">기본요금</span><span class="body">1,600원</span></div>
      <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">전력량요금</span><span class="body">72,400원</span></div>
      <div class="row between" style="padding:6px 0;border-bottom:1px solid var(--divider)"><span class="body-sm">부가가치세</span><span class="body">7,400원</span></div>
      <div class="row between" style="padding:6px 0"><span class="body-sm">전력산업기반기금</span><span class="body">6,100원</span></div>
    `)}
    <div style="height:16px"></div>
    ${T.card(`<div class="row"><div style="flex:1"><div class="h-title">전기 절약 팁</div><div class="body-sm" style="margin-top:2px">에어컨 필터를 주기적으로 청소하면 전기 사용량을 줄일 수 있어요.</div></div></div>`)}
  </div>`);

// ---------- Welfare Center ----------
// 2026-08-29 — 사용자 요청으로 "내 지역" 화면 삭제. 홈의 3번째 카드(공공시설
// 찾기)가 이제 이 화면을 거치지 않고 senior.welfare-search로 바로 이어진다.
S("welfare-search", "경로당", "경로당 검색 (결과/결과 없음)", "44, 45, 46", "검색 진행 → 결과 표시.",
  "검색 흐름 자체를 상태로 보여줌(로딩→결과/결과없음).",
  "결과 없음일 때도 다음 행동(반경 넓히기)을 제공. 2026-08-27: \"근처 경로당 검색 중...\" 문구가 결과가 이미 나온 상태에서도 그대로 남아있어 계속 검색 중인 것처럼 보이던 것 → 상태별로 분리, 결과 상태엔 지역+건수 요약으로 교체.", ["불러오는 중", "결과 있음", "결과 없음"], (ctx, state) => `
  ${T.topBar("경로당 검색")}
  <div class="scr flush" style="padding:0 var(--sp-lg) var(--sp-xxl)">
    ${state === "불러오는 중" ? `<div style="padding:var(--sp-md) 0">${T.loadingState("경로당을 찾고 있어요")}</div>`
      : state === "결과 없음" ? T.emptyState("search_off", "근처에 경로당이 없어요", "검색 범위를 넓혀보세요", "범위 넓히기", "senior.welfare-search")
      : `<div style="padding:var(--sp-md) 0"><span class="body-sm">${ONDAM_DATA.seniorSelf.region} 근처 경로당 ${ONDAM_DATA.welfareCenters.length}곳</span></div>
    <div class="stack welfare-list-cards">${ONDAM_DATA.welfareCenters.map((w) => T.listRow({ leftBadge: T.iconBadgeTint("place", "secondary", "sm"), title: w.name, sub: `${w.addr} · ${w.open ? "운영 중" : "운영 종료"}`, nav: "senior.welfare-detail" })).join("")}</div>`}
  </div>`);

S("welfare-detail", "경로당", "경로당 상세 (전화걸기·길찾기)", "47, 48", "상세 정보 + 전화 연결 + 길찾기.",
  "전화 연결 전 상대방 이름을 다시 보여줘 실수 예방. 2026-08-29 — 사용자 요청으로 Easy 앱의 " +
  "길찾기 버튼을 이식. " +
  "2026-08-29(2차) — 사용자 요청으로 길찾기는 확인 다이얼로그 없이 눌렀을 때 바로 실제 지도(카카오맵 " +
  "검색 링크, 실제 주소 기반)로 이동하게 변경 — 전화걸기는 실수 방지를 위해 확인 다이얼로그를 그대로 " +
  "유지(원칙 7과의 균형: 길찾기는 되돌릴 수 없는 행동이 아니라 그냥 지도를 보여주는 것뿐이라 확인 불필요).",
  "전화걸기는 확인 다이얼로그로 한 번 더 확인, 길찾기는 바로 이동. 2026-08-27: \"취소\"/\"전화하기\" 버튼이 실제로는 아무 동작이 없던 버그를 고침(기본 상태로 되돌아가게). 지역이 실존 지역(상록구)으로 바뀌면서 이 화면도 하드코딩된 가상 장소 대신 welfareCenters[0]을 그대로 참조 — 경로당 자체 공개 번호가 없어 관할 행정복지센터 번호를 쓴다는 안내(phoneNote)를 노출.", ["기본", "전화 확인"], (ctx, state) => {
    const w = ONDAM_DATA.welfareCenters[0];
    const mapUrl = `https://map.kakao.com/link/search/${encodeURIComponent(w.name + " " + w.addr)}`;
    return `
  ${T.topBar(w.name)}
  <div class="scr" style="position:relative;min-height:100%">
    ${T.card(`<div class="h1">${w.name}</div><div class="body-sm" style="margin-top:4px">${w.addr}</div><div class="body-sm" style="margin-top:6px"><span class="badge-dot">운영 중</span></div>${w.phoneNote ? `<div class="body-sm" style="margin-top:8px;color:var(--text-secondary)">${T.msi("info")} ${w.phoneNote}</div>` : ""}`)}
    <div class="stack md" style="margin-top:20px">
      ${T.button("전화 걸기", { variant: "accent", nav: "senior.welfare-detail", large: true, icon: "call", attrs: `data-state="전화 확인"` })}
      <a class="btn secondary large" href="${mapUrl}" target="_blank" rel="noopener">${T.msi("directions")}길 찾기</a>
    </div>
    ${state === "전화 확인" ? T.dialog(`${w.name}에 전화할까요?`, w.phone, `${T.button("취소", { variant: "secondary", nav: "senior.welfare-detail", attrs: `data-state="기본"` })}${T.button("전화하기", { variant: "accent", nav: "senior.welfare-detail", attrs: `data-state="기본"` })}`) : ""}
  </div>`; });

// ---------- More ----------
S("more", "더보기", "더보기", "49", "탭 화면 — 설정/프로필 진입 메뉴.",
  "메뉴는 텍스트 리스트로 단순하게, 아이콘 병행.",
  "2026-08-27: 통계(stats-home/stats-fee/stats-detail) 화면이 앱 어디서도 연결돼 있지 않아 사용자가 절대 도달할 수 없던 것을 발견 — 사용자 확인 후 \"요금 통계\" 항목을 여기 추가. \"로그아웃\"이 자기 자신(senior.more)으로 되돌아가기만 해 눌러도 아무 일도 안 일어나던 것도 로그인 화면으로 이동하게 수정 — 로그아웃은 되돌릴 수 없는 행동이 아니라(다시 로그인하면 됨) 확인 다이얼로그 없이 바로 이동. " +
  "2026-08-29(2차) — Easy 앱의 2열 큰 타일 그리드로 잠시 바꿨다가, " +
  "2026-08-29(4차) — 사용자 요청으로 Senior/Easy 체감 차이를 벌리기 위해 다시 리스트로 되돌린다. 이번엔 " +
  "그냥 나열이 아니라 계정/이용 정보/설정 3개 섹션으로 묶어 \"일반적인 앱의 설정 화면\"에 가까운 밀도로 " +
  "구성 — Easy는 여전히 2열 큰 타일 그대로 둬서(easy.more) 정보 밀도 차이가 뚜렷해진다. " +
  "2026-08-29(5차) — \"알림 설정\" 타일 삭제 — senior.notif-settings가 삭제되고 그 내용이 senior.settings " +
  "안에 인라인됐는데, 이 타일도 결국 senior.settings로 보내면 바로 위 \"설정\" 타일과 중복이라 제거.", null, (ctx) => `
  ${T.topBar("더보기", { back: false })}
  <div class="scr flush" style="padding:0 var(--sp-lg) var(--sp-xxl)">
    <div class="section-title" style="margin-top:14px">계정</div>
    <div class="stack" style="padding-top:4px">
      ${T.listRow({ leftBadge: T.iconBadgeTint("person", "primary", "sm"), title: "프로필", sub: "", nav: "senior.profile" })}
      ${T.listRow({ leftBadge: T.iconBadgeTint("family_restroom", "primary", "sm"), title: "보호자 연결", sub: "", nav: "senior.guardian-link" })}
    </div>
    <div class="section-title" style="margin-top:24px">이용 정보</div>
    <div class="stack" style="padding-top:4px">
      ${T.listRow({ leftBadge: T.iconBadgeTint("bar_chart", "primary", "sm"), title: "요금 통계", sub: "", nav: "senior.stats-home" })}
    </div>
    <div class="section-title" style="margin-top:24px">설정</div>
    <div class="stack" style="padding-top:4px">
      ${T.listRow({ leftBadge: T.iconBadgeTint("settings", "primary", "sm"), title: "설정", sub: "", nav: "senior.settings" })}
      ${T.listRow({ leftBadge: T.iconBadgeTint("accessibility_new", "primary", "sm"), title: "접근성 설정", sub: "", nav: "senior.settings-accessibility" })}
    </div>
    <div style="margin-top:28px">${T.listRow({ leftBadge: T.iconBadgeTint("logout", "danger", "sm"), title: "로그아웃", sub: "", nav: "senior.auth-login" })}</div>
  </div>
  ${T.bottomNavSenior("senior.more")}`);

S("profile", "더보기", "프로필", "50", "내 정보 확인/수정.",
  "정보 항목은 라벨-값 행으로.",
  "수정은 각 행 우측 연필 아이콘으로 진입(별도 화면 없이 인라인). 2026-08-27: 이름이 \"홍길동\"으로 다른 화면(홈 인사말 등)의 seniorSelf.name(김정자)과 안 맞고, 태어난 해도 seniorSelf.age(78세)와 안 맞던 것 → 맞춤. 연필 아이콘도 결정엔 적혀 있는데 실제로는 없어 추가(인라인 편집 로직까지는 이 리뷰 범위 밖).", null, (ctx) => `
  ${T.topBar("프로필")}
  <div class="scr">
    ${(() => {
      const pencil = `<span class="msi" style="font-size:18px;color:var(--text-disabled)">edit</span>`;
      const row = (label, value) => `<div class="row between"><span class="body-sm">${label}</span><span class="row" style="gap:6px"><span class="body">${value}</span>${pencil}</span></div>`;
      return T.card(`${row("이름", ONDAM_DATA.seniorSelf.name)}<div style="height:12px"></div>${row("전화번호", "010-1234-5678")}<div style="height:12px"></div>${row("태어난 해", "1951")}`);
    })()}
  </div>`);

S("settings", "더보기", "설정", "51", "일반 설정 목록.",
  "설정은 카테고리별로 묶어 스크롤 부담 감소.",
  "위험한 설정(탈퇴)은 맨 아래 별도 구분. " +
  "2026-08-29 — 사용자 질문(\"접근성/알림을 굳이 나눠놓을 필요가 있어?\")에 대한 절충안으로 진행: " +
  "접근성은 하위에 3항목(글자크기/음성안내/언어)이 더 있어 독립된 목록 페이지로 남기고, 알림은 토글 " +
  "2개뿐이라 한 번 더 들어갈 필요가 없어 이 화면에 바로 인라인으로 넣었다(notif-settings 화면 삭제). " +
  "더보기 메뉴의 \"알림 설정\" 타일도 이제 여기(설정)와 같은 목적지라 중복이라 제거.", ["on", "off"], (ctx, state) => `
  ${T.topBar("설정")}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    <div class="stack" style="padding-top:8px">
      ${T.listRow({ title: "접근성", sub: "글자 크기, 쉬운 모드", nav: "senior.settings-accessibility" })}
      ${T.listRow({ title: "보호자 연결", sub: "1명 연결됨", nav: "senior.guardian-link" })}
    </div>
    <div class="section-title" style="margin-top:24px">알림</div>
    <div class="stack md" style="padding-top:4px">
      ${T.card(`<div class="row">${T.iconBadgeTint("warning", "danger")}<div style="flex:1"><span class="h-title">위험 알림</span></div><span class="caption">항상 켜짐</span></div>`)}
      ${T.card(`<div class="row">${T.iconBadgeTint("notifications", "primary")}<div style="flex:1"><span class="h-title">기록 저장 알림</span></div><button class="toggle ${state === "on" ? "on" : ""}" data-state="${state === "on" ? "off" : "on"}"></button></div>`)}
    </div>
  </div>`);

// 2026-08-27 — 온보딩(onboard-settings)은 3항목을 한 화면에 묶어 빠르게
// 훑게 하지만, 나중에 하나만 바꾸러 들어오는 설정 메뉴에서는 각각 별도
// 페이지로 나눈다(설정 메뉴의 일반적인 드릴다운 패턴 — 매번 3항목을 전부
// 다시 스크롤하지 않아도 됨).
S("settings-accessibility", "더보기", "접근성 설정", "52", "글자 크기/음성 안내/언어 각각 별도 페이지로 진입하는 목록.",
  "설정 메뉴는 드릴다운 리스트가 관례(항목별 독립 진입).",
  "온보딩과 달리 한 화면에 묶지 않고 항목별로 분리 — 하나만 바꾸러 온 사용자가 나머지를 스크롤하지 않게.", null, (ctx) => `
  ${T.topBar("접근성 설정")}
  <div class="scr flush" style="padding:0 var(--sp-lg)">
    <div class="stack" style="padding-top:8px">
      ${T.listRow({ title: "글자 크기", sub: "보통", nav: "senior.settings-textsize" })}
      ${T.listRow({ title: "음성 안내", sub: "켜짐", nav: "senior.settings-voice" })}
      ${T.listRow({ title: "언어", sub: "한국어", nav: "senior.settings-language" })}
    </div>
  </div>`);

S("settings-textsize", "더보기", "글자 크기", "52", "글자 크기만 단독으로 재설정.",
  "드릴다운 설정 페이지 — 항목 하나만.",
  "온보딩 카드와 동일한 컴포넌트 재사용, 라디오 카드 3개만.", ["보통", "크게", "아주 크게"], (ctx, state) => {
    const sizes = { 보통: 22, 크게: 28, "아주 크게": 34 };
    const descs = { 보통: "가장 많이 선택해요.", 크게: "더 크게 보실 수 있어요.", "아주 크게": "가장 크게 보여드려요." };
    const zoom = { 보통: 1, 크게: 1.15, "아주 크게": 1.3 }[state];
    return `
  ${T.topBar("글자 크기")}
  <div class="scr" style="zoom:${zoom}">
    <div class="stack md">
      ${["보통", "크게", "아주 크게"].map((s) => `
        <button class="textsize-option ${s === state ? "active" : ""}" data-state="${s}">
          ${s === state ? `<span class="chk">${T.msi("check")}</span>` : `<span style="width:22px"></span>`}
          <span class="txt"><span class="tt">${s}</span><span class="ds">${descs[s]}</span></span>
          <span class="sample" style="font-size:${sizes[s]}px">A</span>
        </button>`).join("")}
    </div>
  </div>`; });

S("settings-voice", "더보기", "음성 안내", "52", "음성 안내만 단독으로 재설정.",
  "드릴다운 설정 페이지 — 항목 하나만.",
  "토글 하나 + 설명 한 줄, 그 이상 옵션을 늘리지 않음. 2026-08-27: 카드 하나만 덩그러니 있어 휑해 보이던 것 → 다른 화면들처럼 아이콘 배지를 붙여 시각적 무게를 보완.", ["off", "on"], (ctx, state) => `
  ${T.topBar("음성 안내")}
  <div class="scr">
    ${T.card(`<div class="row">${T.iconBadgeTint("record_voice_over", "primary")}<div style="flex:1"><div class="h-title">음성으로 안내해드려요</div><div class="body-sm">화면을 읽어드려요</div></div><button class="toggle ${state === "on" ? "on" : ""}" data-state="${state === "on" ? "off" : "on"}"></button></div>`)}
  </div>`);

S("settings-language", "더보기", "언어", "52", "언어만 단독으로 재설정.",
  "드릴다운 설정 페이지 — 항목 하나만.",
  "4개 언어를 2x2 그리드로, 선택된 언어만 강조. " +
  "2026-08-29 — 사용자 요청으로 2x2 작은 사각형 대신 1열로 세워 화면 너비를 꽉 채우는 긴 직사각형 " +
  "4개로 변경(onboard-settings의 언어 섹션도 동일하게). " +
  "2026-08-29(2차) — 사용자 요청으로 버튼 크기를 더 키움 — 기본 .chip(min-height:48px, 13.5px 글자)은 " +
  "다른 화면의 작은 필터 칩과 같은 크기라 이 화면의 주 선택지로는 작아 보였다.", ["한국어", "English", "日本語", "中文"], (ctx, state) => `
  ${T.topBar("언어")}
  <div class="scr">
    <div class="stack" style="gap:10px">
      ${["한국어", "English", "日本語", "中文"].map((l) => `<button class="chip ${l === state ? "active" : ""}" data-state="${l}" style="width:100%;justify-content:center;min-height:64px;font-size:18px;font-weight:800">${l}</button>`).join("")}
    </div>
  </div>`);

S("guardian-link", "더보기", "보호자 연결", "53", "보호자 연결 상태 관리 진입.",
  "연결 해제는 위험 행동으로 별도 확인(원칙 7).",
  "2026-08-27: \"아드님\"으로만 뭉뚱그려 있던 걸 guardianContact 이름(김수민)으로 맞춤(문자 분석의 보호자 알림 안내 화면과 동일 기준). " +
  "2026-08-29 — 사용자 요청으로 보호자 정보 카드와 \"연결 해제하기\" 버튼을 하나로 합쳤다: 이전엔 정보 " +
  "카드 아래 별도 ghost 버튼이 한 줄 더 있었는데, 이제 카드 안에 \"해제\" 텍스트 링크를 같은 줄에 넣어 " +
  "\"이 보호자에 대한 카드\" 하나로 인지되게 했다 — 해제 확인 다이얼로그 흐름은 그대로 유지(원칙 7).", ["기본", "해제 확인"], (ctx, state) => `
  ${T.topBar("보호자 연결")}
  <div class="scr" style="position:relative;min-height:100%">
    ${T.card(`<div class="row">${T.iconBadgeTint("person", "primary", "sm")}<div style="flex:1"><div class="h-title">${ONDAM_DATA.guardianContact.name}</div><div class="body-sm">연결됨 · 2026.06.01</div></div><button class="btn ghost" style="width:auto;padding:4px 6px" data-nav="senior.guardian-link" data-state="해제 확인">해제</button></div>`)}
    <div style="margin-top:24px">${T.button("새 보호자 연결하기", { variant: "accent", nav: "senior.qr-generate", large: true })}</div>
    ${state === "해제 확인" ? T.dialog(`${ONDAM_DATA.guardianContact.name}님과의 연결을 해제할까요?`, "해제하면 위험 알림을 더 이상 받지 못해요.", `${T.button("취소", { variant: "secondary", nav: "senior.guardian-link", attrs: `data-state="기본"` })}${T.button("해제하기", { variant: "emergency", nav: "senior.guardian-link", attrs: `data-state="기본"` })}`) : ""}
  </div>`);

S("qr-generate", "더보기", "QR 생성", "54", "보호자 연결용 QR 코드 발급.",
  "사용자 제공 레퍼런스 그대로 — 큰 헤드라인 아래 QR, 스캔 시 요청이 전달됨을 안내. " +
  "2026-08-29 — 사용자 요청으로 뒤로가기 버튼 추가: 이 화면은 더보기 → 보호자 연결 → " +
  "\"새 보호자 연결하기\"로만 들어오므로, 뒤로가기는 항상 보호자 연결로 돌아간다(온보딩 중 QR 안내는 " +
  "senior.onboard-qr이라는 별도 화면이라 영향 없음).",
  "5분 후 자동 만료 안내 + 재생성 버튼은 헤드라인 아래로. " +
  "2026-08-29(2차) — 사용자 지적으로 버그 발견: 뒤로가기를 data-nav=\"senior.guardian-link\"(goTo, " +
  "history에 push)로 만들었더니, goTo가 이 화면 자체를 history에 push하고 나서 이동해 보호자 연결 " +
  "화면의 history 맨 위에 \"QR 생성\"이 쌓였다 — 그 상태에서 보호자 연결의 (data-back=goBack, history " +
  "pop) 뒤로가기를 누르면 방금 쌓인 QR 생성으로 다시 돌아가버리는 오류였다. data-back(goBack)으로 " +
  "바꿔 history를 오염시키지 않게 수정 — 이 화면은 보호자 연결에서만 들어오므로 goBack()으로도 항상 " +
  "보호자 연결로 돌아간다.", null, (ctx) => `
  <div class="top-bar"><button class="back" data-back>${T.msi("arrow_back")}</button></div>
  <div class="scr center" style="min-height:calc(100% - 46px)">
    <h1 class="h1" style="margin-top:8px">보호자에게 이 QR을<br>보여주세요</h1>
    <div style="margin-top:20px">${T.qrBox()}</div>
    <p class="body-sm" style="margin:16px 0 24px">보호자가 QR을 스캔하면<br>연결 요청이 도착합니다</p>
    ${T.button("새로고침", { variant: "secondary", nav: "senior.qr-generate", large: true })}
  </div>`);

// 2026-08-29 — 사용자 요청으로 "연결 상태" 화면 삭제 — guardian-link가 이미
// 카드(이름+연결일)를 보여주고 해제 액션까지 한 곳에 있어 내용이 거의
// 그대로 중복이었다. settings의 "보호자 연결" 항목도 guardian-link로 바로
// 연결하도록 변경.

// 2026-08-29 — 사용자 요청으로 "알림 설정" 별도 화면 삭제 — 토글 2개뿐이라
// senior.settings 화면 안에 바로 인라인됐다(위 S("settings") 참고).
