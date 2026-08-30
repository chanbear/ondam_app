// Easy 화면 레지스트리. 2026-08-27(3차) — 사용자 요청으로 쉬운 모드를
// senior.home의 상태 토글이 아니라 ONDAM 2.0 아래 Senior/Guardian과 같은
// 층위의 별도 앱으로 분리한다. 홈은 카테고리 구분 없이 문서읽기 → 문자확인
// → 경로당찾기 → 말로물어보기 → 긴급도움 순서로 나열하고, 쉬운모드 토글은
// 화면 맨 위로 옮긴다. 5개 핵심 기능에 연결되는 화면도 전부 Easy 전용으로
// 새로 만든다(사용자가 "모든 연결 화면까지 전부" 만들라고 명시적으로 확인).
// Senior의 doc-result/msg-result와 그 렌더 함수(analysisResultBody), .rsl-*
// CSS는 손대지 않는다. 다만 2026-08-27(4차) — 사용자 요청으로 분석 결과
// 화면은 그 함수를 재사용하지 않고 Easy 전용으로 새로 만든다: 정보 밀도
// 높은 3단 그리드/별점/체크박스/공유 대신, 한 번에 읽을 정보만 세로로 크게
// 쌓은 easyResultBody()를 별도로 둔다(.easy-rsl-* CSS, .rsl-*와 별개 네임스페이스).
const EASY_SCREENS = [];
function E(id, cat, title, spec, purpose, ref, decision, states, render) {
  EASY_SCREENS.push({ id: "easy." + id, app: "easy", cat, title, spec, purpose, ref, decision, states: states || ["기본"], render });
}

// ---------- 로그인 ----------
// 2026-08-28 — 사용자 요청: "초기에 로그인 화면부터 ... 쉬운 모드로 변경".
// legacy-cleaned/senior-easy.html "로그인 · 시작하기" 화면(전화번호+비밀번호
// + 구글/네이버/카카오 소셜 로그인 + 게스트 진입)을 그대로 ui-prototype
// 컴포넌트 언어로 옮긴다. 온보딩 전체(글자크기/프로필/QR 등)는 이번 요청
// 범위 밖으로 판단 — 로그인 화면 하나만 추가.
E("auth-login", "로그인", "온담 시작하기", "1", "Easy 앱 진입점 — 전화번호 로그인 + 소셜 로그인 + 게스트 진입.",
  "legacy-cleaned/senior-easy.html의 '로그인 · 시작하기' 화면 그대로.",
  "전화번호/비밀번호 입력 + 로그인 버튼 + 구글·네이버·카카오 소셜 로그인 + '회원가입 없이 사용하기' 게스트 링크. 전부 easy.home으로 이어진다. " +
  "2026-08-29 — 문구 톤 정리(짧고 친근하게).", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadgeTint("shield_person", "primary", "lg")}
    <h1 class="h1" style="margin-top:12px">온담 시작하기</h1>
    <p class="body-sm" style="margin-bottom:var(--sp-lg)">전화번호로 시작해요</p>
    <div class="field" style="width:100%;margin-bottom:14px;text-align:left"><label>휴대폰 번호</label><input type="tel" placeholder="010-0000-0000" readonly /></div>
    <div class="field" style="width:100%;text-align:left"><label>비밀번호</label><input type="password" placeholder="••••" readonly /></div>
    <div style="width:100%;margin-top:var(--sp-md)">${T.button("로그인 · 회원가입", { variant: "accent", nav: "easy.onboard-settings", large: true })}</div>
    <div class="or-div">또는</div>
    <button class="social-btn google" data-nav="easy.home"><svg width="18" height="18" viewBox="0 0 18 18"><path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.9c1.7-1.57 2.7-3.88 2.7-6.62z"/><path fill="#34A853" d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.9-2.26c-.81.54-1.85.86-3.06.86-2.35 0-4.34-1.59-5.05-3.72H.96v2.33A9 9 0 0 0 9 18z"/><path fill="#FBBC05" d="M3.95 10.7A5.4 5.4 0 0 1 3.67 9c0-.59.1-1.16.28-1.7V4.97H.96A9 9 0 0 0 0 9c0 1.45.35 2.83.96 4.03l2.99-2.33z"/><path fill="#EA4335" d="M9 3.58c1.32 0 2.51.46 3.44 1.35l2.58-2.58C13.46.89 11.43 0 9 0A9 9 0 0 0 .96 4.97l2.99 2.33C4.66 5.17 6.65 3.58 9 3.58z"/></svg>구글 로그인</button>
    <button class="social-btn naver" data-nav="easy.home"><span class="badge">N</span>네이버 로그인</button>
    <button class="social-btn kakao" data-nav="easy.home"><span class="badge">TALK</span>카카오 로그인</button>
    <button class="btn ghost" data-nav="easy.home" style="text-decoration:underline;margin-top:6px">회원가입 없이 사용하기</button>
  </div>`);

// 2026-08-28 — 사용자가 미리캔버스 온보딩 슬라이드 2장을 보여주며 요청한
// 온보딩 흐름의 2~3단계. easy.settings(더보기>설정)와 같은 3항목(글자크기/
// 음성안내+속도/언어)이지만, 신규 가입 온보딩용이라 "아주 크게"를 기본
// 선택해두고(쉬운 모드 신규 가입이니) 뒤로가기 대신 "다음" 버튼으로 다음
// 온보딩 단계(easy.onboard-profile)로 넘어간다.
E("onboard-settings", "로그인", "화면/음성/언어 설정", "8,9", "온보딩 2단계 — easy.settings와 같은 3항목, '다음'으로 다음 온보딩 단계로.",
  "senior.onboard-settings/easy.settings와 동일한 글자크기·음성안내+속도·언어 3항목.",
  "\"아주 크게\"를 기본 선택(쉬운 모드 신규 가입 흐름이므로). 하단 '다음' 버튼으로 easy.onboard-profile로. " +
  "2026-08-29 — 문구 톤 정리(짧고 친근하게).", null, (ctx) => `
  <div class="scr">
    <h1 class="h1" style="margin-top:8px">몇 가지만<br>정해주세요</h1>
    <p class="body-sm" style="margin:6px 0 0">먼저 편하게 설정할게요</p>

    <div class="section-title" style="margin-top:24px">글자 크기</div>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">
      ${["보통", "크게", "아주 크게"].map((s) => `<button class="chip ${s === "아주 크게" ? "active" : ""}" style="width:100%;justify-content:center">${s}</button>`).join("")}
    </div>

    <div class="section-title" style="margin-top:28px">음성 안내</div>
    ${T.card(`<div class="row"><div style="flex:1"><div class="h-title">음성으로 안내해드려요</div><div class="body-sm">화면을 읽어드려요</div></div><button class="toggle on"></button></div>`)}
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-top:12px">
      ${["1배", "1.2배", "1.5배", "2배"].map((v) => `<button class="chip ${v === "1배" ? "active" : ""}" style="width:100%;justify-content:center">${v}</button>`).join("")}
    </div>

    <div class="section-title" style="margin-top:28px">언어</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
      ${["한국어", "English", "日本語", "中文"].map((l) => `<button class="chip ${l === "한국어" ? "active" : ""}" style="width:100%;justify-content:center">${l}</button>`).join("")}
    </div>

    <div style="margin-top:28px">${T.button("다음", { variant: "accent", nav: "easy.onboard-profile", large: true })}</div>
  </div>`);

E("onboard-profile", "로그인", "개인 맞춤화 설정", "11", "온보딩 3단계 — 이름/성별/나이/사는 지역 입력.",
  "senior.onboard-profile을 참고하되 참고 이미지대로 성별 필드 추가.",
  "필수 정보 입력 후 '다음'으로 다음 온보딩 단계(easy.onboard-qr)로, '건너뛰기'는 온보딩을 마치고 easy.home으로. " +
  "2026-08-29 — 문구 톤 정리(짧고 친근하게).", null, (ctx) => `
  <div class="scr">
    <h1 class="h1" style="margin-top:8px">몇 가지만<br>알려주시겠어요?</h1>
    <p class="body-sm" style="margin:6px 0 0">더 맞는 정보를 드릴게요</p>

    <div class="field" style="margin-top:20px"><label>이름</label><input placeholder="이름을 입력해주세요" readonly /></div>
    <div class="field" style="margin-top:14px">
      <label>성별</label>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
        <button class="chip active" style="width:100%;justify-content:center">남성</button>
        <button class="chip" style="width:100%;justify-content:center">여성</button>
      </div>
    </div>
    <div class="field" style="margin-top:14px"><label>나이</label><input placeholder="만 나이를 입력해주세요" readonly /></div>
    <div class="field" style="margin-top:14px"><label>사는 지역</label><input placeholder="시/군/구까지 입력해주세요" readonly /></div>

    <div class="stack md" style="margin-top:24px">
      ${T.button("내 현재 위치 입력하기", { variant: "secondary", icon: "my_location" })}
      ${T.button("다음", { variant: "accent", nav: "easy.onboard-qr", large: true })}
      <button class="btn ghost" data-nav="easy.home">건너뛰기</button>
    </div>
  </div>`);

// ---------- 홈 ----------
// 2026-08-28 — 참고 이미지 기반으로 top-bar(스피커·온담 워드마크·일반모드
// 링크)와 하단 탭바는 채택하되, 사용자가 "위에 있는 구성을 저렇게 나누지
// 말고 기존에 있던 직사각형 길게" 나열해달라고 명시적으로 되돌려서, 버튼은
// 2열 카드가 아니라 원래의 전체너비 `.easy-btn` 세로 스택으로 되돌린다.
// 말로물어보기도 상단 스피커 아이콘뿐 아니라 목록에도 다시 넣는다(이미지엔
// 없었지만 사용자가 4개 항목에 다시 포함하라고 명시).
E("home", "홈", "홈", "14, 15", "Easy 앱의 진입점 — 상단은 쉬운모드 토글 행(사용자 제공 참고 이미지), 버튼은 전체너비 스택.",
  "senior.home의 카드형 레이아웃을 재사용하되, 부제/음성 FAB 등 부가 정보를 없애고 큰 버튼 리스트로 단순화.",
  "상단: \"쉬운 모드 / 지금 쉬운 모드로 보고 있어요\" + 켜짐 상태 토글(누르면 senior.home Normal로 이동 — 원래 senior.home 토글과 같은 기능). \"무엇을 도와드릴까요?\" 헤드라인. 문서촬영/문자분석/경로당찾기/말로물어보기 4개를 전체너비 카드로 세로 나열. 하단 탭바 5개, 도움 탭은 danger 톤으로 항상 튀게.", null, (ctx) => `
  <div class="scr">
    <div class="row" style="padding-bottom:14px;margin-bottom:18px;border-bottom:1px solid var(--divider)">
      <div style="flex:1">
        <div class="h-title">쉬운 모드</div>
        <div class="body-sm">지금 쉬운 모드로 보고 있어요</div>
      </div>
      <button class="toggle on" data-nav="senior.home"></button>
    </div>
    <div class="h1" style="margin-bottom:var(--sp-lg)">무엇을 도와드릴까요?</div>
    <div class="stack lg">
      <div class="easy-btn" data-nav="easy.doc-start">${T.iconBadge("photo_camera", "primary", "lg")}<span class="lbl">문서 촬영하기</span></div>
      <div class="easy-btn" data-nav="easy.msg-list">${T.iconBadge("sms", "primary", "lg")}<span class="lbl">문자 분석하기</span></div>
      <div class="easy-btn" data-nav="easy.welfare-region">${T.iconBadge("place", "primary", "lg")}<span class="lbl">경로당 찾기</span></div>
      <div class="easy-btn" data-nav="easy.voice">${T.iconBadge("mic", "primary", "lg")}<span class="lbl">말로 물어보기</span></div>
    </div>
  </div>
  ${T.bottomNavEasy("easy.home")}`);

// ---------- 문서 읽기 ----------
// 2026-08-28 — 참고 이미지의 [문서 분석] 화면 기반: "AI 분석하기" 타이틀 +
// 메뉴 아이콘, "음성 안내 다시 듣기", 촬영/불러오기 2열 카드, 팁 카드.
E("doc-start", "문서 읽기", "문서 읽기 시작", "18", "문서 촬영 진입 안내 — 참고 이미지 기반 재설계.",
  "senior.doc-start와 같은 흐름, 레이아웃은 참고 이미지의 [문서 분석] 화면.",
  "촬영하기/불러오기를 정사각형 2열 카드가 아니라 홈 화면과 같은 전체너비 긴 직사각형 버튼으로(사용자가 되돌려달라고 명시) + \"꼭 확인해 주세요!\" 팁 카드로 정확도 팁 전달. " +
  "2026-08-29 — 사용자 요청으로 Senior/Easy 문구 톤 차이를 벌리기 위해 팁 카드 문구를 더 짧고 " +
  "친근하게 다듬었다(Senior의 doc-start는 손대지 않고 그대로 둔다).", null, (ctx) => `
  ${T.topBar("AI 분석하기", { right: `<button class="right-action" style="width:44px;height:44px;display:flex;align-items:center;justify-content:center;flex:none">${T.msi("menu")}</button>` })}
  <div class="scr">
    <button class="btn ghost" data-speak="고지서나 안내문을 촬영하면 읽어드려요. 글씨가 잘 보이게 찍어주세요. 밝은 곳에서 찍으면 더 정확해요." style="margin-bottom:var(--sp-md)">${T.msi("volume_up")}음성 안내 다시 듣기</button>
    <div class="stack md" style="margin-bottom:var(--sp-md)">
      <div class="easy-btn" data-nav="easy.doc-camera">${T.iconBadge("photo_camera", "primary", "lg")}<span class="lbl">사진 촬영하기</span></div>
      <div class="easy-btn" data-nav="easy.doc-camera">${T.iconBadge("photo_library", "primary", "lg")}<span class="lbl">사진 불러오기</span></div>
    </div>
    ${T.card(`<div class="h-title" style="margin-bottom:8px">${T.msi("info")} 이렇게 찍어주세요!</div><div class="body-sm" style="line-height:1.6">· 글씨가 잘 보이게 찍어주세요<br>· 밝은 곳에서 찍으면 더 정확해요</div>`)}
  </div>`);

E("doc-camera", "문서 읽기", "카메라", "19", "실제 촬영 화면 — Senior doc-camera와 동일 구조.",
  "senior.doc-camera 재사용(어두운 배경 + 점선 프레임 + 큰 셔터).",
  "구성은 원본과 동일, nav만 easy 체인으로 교체. 2026-08-29 — 문구 톤 정리(짧고 친근하게).", null, (ctx) => `
  <div class="scr flush" style="background:#111;min-height:100%;display:flex;flex-direction:column;color:#fff">
    <div class="top-bar" style="color:#fff"><button class="back" style="color:#fff" data-back>${T.msi("close")}</button><h1 style="color:#fff">문서 촬영</h1><button class="right-action" style="color:#fff;width:44px;height:44px;display:flex;align-items:center;justify-content:center;flex:none">${T.msi("flash_off")}</button></div>
    <div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:24px">
      <div style="width:100%;max-width:280px;aspect-ratio:3/4;border:2px dashed rgba(255,255,255,.5);border-radius:var(--r-lg)"></div>
      <div style="color:#999;font-size:13px">화면 안에 맞춰주세요</div>
    </div>
    <div style="display:flex;justify-content:center;padding:24px"><button data-nav="easy.doc-captured" style="width:76px;height:76px;border-radius:50%;background:#fff;border:6px solid var(--accent)"></button></div>
  </div>`);

// 2026-08-28 — 사용자 제공 참고 이미지 기반 재설계: "찍은 사진" 큰 제목 +
// "1장을 찍으셨어요." + 작은 확인 배지가 겹친 미리보기 + 여러 장 촬영
// 안내문 + 사진 더 찍기/분석하기 버튼. 참고 이미지에 있던 "음성 안내
// 사용하기" 토글/문구는 사용자가 명시적으로 빼달라고 해서 제외.
E("doc-captured", "문서 읽기", "촬영 확인", "20", "촬영 결과 확인, 재촬영/다음 — 참고 이미지 기반 재설계.",
  "senior.doc-captured 대신 참고 이미지의 [찍은 사진] 화면 그대로(음성 관련 토글/문구만 제외).",
  "미리보기 좌상단에 작은 확인 배지를 겹쳐 촬영 완료를 시각적으로 보여준다. \"사진 더 찍기\"(보조)/\"분석하기\"(주요) 2개 버튼. " +
  "2026-08-29 — 문구 톤 정리(짧고 친근하게).", null, (ctx) => `
  <div class="top-bar">
    <button class="back" style="width:auto" data-back>${T.msi("arrow_back")}홈으로</button>
  </div>
  <div class="scr">
    <div class="h1" style="margin-bottom:4px">찍은 사진</div>
    <p class="body-sm" style="margin-bottom:var(--sp-lg)">1장 찍으셨어요.</p>
    <div style="position:relative;aspect-ratio:3/4;background:var(--surface);border-radius:var(--r-lg);display:flex;align-items:center;justify-content:center">
      ${T.iconBadgeTint("description", "primary", "lg")}
      <span style="position:absolute;top:10px;left:10px">${T.iconBadge("check", "primary", "sm")}</span>
    </div>
    <p class="body-sm" style="margin-top:var(--sp-md);line-height:1.6">여러 장 찍어도 돼요. 알아서 구분해 드려요.</p>
    <div class="stack md" style="margin-top:var(--sp-lg)">
      ${T.button("사진 더 찍기", { variant: "secondary", nav: "easy.doc-camera", icon: "photo_camera" })}
      ${T.button("분석하기", { variant: "accent", nav: "easy.doc-analyzing", large: true })}
    </div>
  </div>`);

E("doc-analyzing", "문서 읽기", "분석 중", "21", "AI 분석 진행 상태.",
  "senior.doc-analyzing 재사용 — 진행률(%) UI.",
  "\"온담이 열심히 분석하고 있어요\" + 진행바.", null, (ctx) => `
  <div class="scr center">
    <div style="font-size:40px;font-weight:800;color:var(--primary);letter-spacing:-.5px">67%</div>
    <div class="confidence-bar" style="width:100%;max-width:260px;margin-top:16px"><i style="width:67%"></i></div>
    <p class="body" style="margin-top:20px;font-weight:700">온담이 열심히 분석하고 있어요</p>
  </div>`);

// 2026-08-27(4차) — 사용자 요청으로 Easy 전용 분석 결과를 새로 만든다.
// Senior/Guardian이 공유하는 analysisResultBody()/.rsl-*(3단 정보 그리드 +
// 별점 신뢰도 + 체크박스 할 일 + 상세 정보 아코디언)는 정보 밀도가 높아
// 쉬운 모드의 "한 번에 읽을 정보만 크게" 원칙과 맞지 않아 재사용하지 않는다
// — 손대지도 않는다. 대신 위험도 배지 → 한 문장 요약 → 핵심 정보 2줄 →
// "이렇게 해보세요" 2가지만 세로로 쌓는다. 문서/문자 내용은 각각 실제
// 시나리오(전기요금 고지서 / 계좌 도용 사칭 문자, msg-result-real과 동일
// 시나리오)에 맞춘다 — analysisResultBody()처럼 문자 결과에 고지서 내용이
// 나오는 불일치를 만들지 않는다.
// 2026-08-28(3차 수정) — 사용자가 새 참고 이미지("건강검진 대상자 안내"
// 예시)를 제시하며 "이런 느낌으로 만들어줘, 완전히 똑같이는 하지 말고"라고
// 요청 — 직전의 초미니멀 버전(배지+한 문장+큰 아이콘 하나)에서 한 단계
// 되돌려, 참고 이미지의 구조(헤드라인 → 기한/보낸사람 하이라이트 카드 →
// 체크리스트 → "이 문서에 대해 물어보기")를 가져오되 그대로 베끼지 않고
// 우리 배지+행동아이콘("그림으로 표시" 요청, 직전 지시)은 유지한 채 위에
// 얹는다. 문서종류 표/"왜 판단했나요" 이유설명 카드는 여전히 넣지 않는다
// (그 부분은 이번 참고 이미지에도 없음 + 이전 삭제 지시와도 일치).
// 2026-08-28(5차) — 사용자가 같은 참고 이미지를 세 번째로 가리키며 이번엔
// "구조를 그대로 유지하고 디자인만 우리 디자인에 맞춰줘"라고 명확히 요청 —
// 이전 지시("완전히 똑같이는 하지 말고")와 달리 이번엔 정보 구조 자체를
// 참고 이미지 순서 그대로 따른다: 작은 배지 → 헤드라인(굵은 한 문장) →
// 일러스트 → 기한/발신 하이라이트 카드 → 종류 태그 → "AI 요약" 섹션(문단) →
// 체크리스트(항목마다 작은 확인 표시) → 물어보기 → 확인 완료. 색/폰트/
// 테두리만 우리 토큰으로 — 문구/카피는 그대로 베끼지 않고 우리 시나리오
// (전기요금 고지서/택배사칭 문자)에 맞춰 새로 쓴다.
function easyResultBody(kind, state, confirmNav) {
  const tone = state === "위험" ? "dangerous" : state === "주의" ? "caution" : "safe";
  const icon = { safe: "verified", caution: "error", dangerous: "warning" }[tone];
  const isDoc = kind === "doc";
  const headline = isDoc
    ? { safe: `이번 달 전기요금은 87,500원이에요.`, caution: `전기요금 납부 기한이 얼마 남지 않았어요.`, dangerous: `공식 고지서에 없는 계좌로 입금을 요구하고 있어요.` }[tone]
    : { safe: `평소와 같은 정상적인 문자예요.`, caution: `평소와 다른 번호로 온 문자예요.`, dangerous: `택배 반송을 핑계로 이상한 주소를 누르게 하는 사기 문자로 보여요.` }[tone];
  const typeTag = isDoc ? "한국전력(전기요금 고지서)" : "택배사 사칭 문자";
  const highlight = isDoc
    ? { k: "납부 기한", safe: ["2026.08.25", "여유 있게 남았어요"], caution: ["2026.08.25", "내일까지예요"], dangerous: ["확인 필요", "공식 계좌가 아니에요"] }
    : { k: "보낸 사람", safe: ["CJ대한통운(공식)", "정상 발신 번호예요"], caution: ["010-****-2231", "등록되지 않은 번호예요"], dangerous: ["010-****-2231", "택배사 공식 번호가 아니에요"] };
  const [hVal, hNote] = highlight[tone];
  const aiSummary = isDoc
    ? { safe: "이번 달 전기 사용량은 지난달과 비슷한 수준이에요. 별도로 확인하실 내용은 없지만, 납부일은 놓치지 않게 챙겨주세요.", caution: "이번 달 전기요금 고지서예요. 납부 기한이 얼마 남지 않았으니 금액을 확인하고 기한 안에 납부해주세요.", dangerous: "이 고지서는 실제 한국전력 계좌가 아닌 다른 계좌로 입금을 요구하고 있어요. 정상적인 고지서라면 이런 요구를 하지 않으니, 이 계좌로는 입금하지 마세요." }[tone]
    : { safe: "발신 번호와 문구 모두 실제 택배사 안내와 일치해요. 특별히 조심할 내용은 없어요.", caution: "평소 받던 번호와 다른 곳에서 왔어요. 내용 자체에 위험한 요구는 없지만 한 번 더 확인해보는 게 좋아요.", dangerous: "실제 택배사는 문자로 인터넷 주소 클릭이나 개인정보를 요구하지 않아요. 이 문자는 반송을 핑계로 링크를 누르게 유도하는 전형적인 사기 수법이에요." }[tone];
  const checklist = isDoc
    ? { safe: ["다음 달 사용량도 한번 확인해보기"], caution: ["기한(08.25) 안에 금액 확인하고 납부하기", "다음 달 사용량도 한번 확인해보기"], dangerous: ["이 계좌로 입금하지 않기", "한국전력 정식 채널(국번없이 123)로 다시 확인하기"] }[tone]
    : { safe: ["의심되면 언제든 다시 확인해요"], caution: ["링크를 누르기 전에 한 번 더 확인하기", "확실하지 않으면 보호자에게 물어보기"], dangerous: ["이 번호로 답장하거나 전화하지 않기", "문자 속 링크는 절대 누르지 않기"] }[tone];
  const askLabel = isDoc ? "이 문서에 대해 물어보기" : "이 문자에 대해 물어보기";
  // 2026-08-28(7차) — 사용자가 같은 참고 이미지를 다시 보여주며 "이걸
  // 배경색만 바꿔서 똑같이 만들어줘"라고 명시적으로 요청 — 이번엔 "구조만
  // 같게, 디자인은 우리 걸로"가 아니라 페이지 배경색(--bg, 우리 토큰)
  // 외에는 참고 이미지를 그대로 재현한다: 굵은 먹색 테두리 대신 얇은
  // 테두리+옅은 그림자의 부드러운 카드, 사람이 있는 컬러 일러스트(어르신 +
  // 상담사가 서류를 주고받는 장면), 확인 버튼은 참고 이미지처럼 초록색
  // (--success 토큰, 사이트 전역 --accent/파랑은 건드리지 않는다).
  const illustration = isDoc
    ? `<svg viewBox="0 0 200 150" width="100%" height="150" role="presentation">
        <circle cx="100" cy="78" r="66" fill="#FBEEDD" />
        <path d="M30 148c1-24 16-38 34-38s33 14 34 38" fill="#D7DEE8" />
        <circle cx="64" cy="96" r="19" fill="#F4C9A0" />
        <path d="M47 92a17 17 0 0 1 34 0c0-9-7-15-17-15s-17 6-17 15z" fill="#B8B8B8" />
        <path d="M112 148c1-22 15-35 32-35s31 13 32 35" fill="#8FC7DE" />
        <circle cx="144" cy="98" r="18" fill="#F6D3B0" />
        <path d="M130 92c0-9 6-16 14-16s14 7 14 16" fill="#5B4632" />
        <rect x="88" y="104" width="34" height="24" rx="5" fill="#fff" stroke="var(--risk)" stroke-width="3" />
        <rect x="93" y="110" width="20" height="4" rx="2" fill="var(--risk-soft)" />
        <rect x="93" y="117" width="14" height="4" rx="2" fill="var(--risk-soft)" />
      </svg>`
    : `<svg viewBox="0 0 200 150" width="100%" height="150" role="presentation">
        <circle cx="100" cy="78" r="66" fill="#FBEEDD" />
        <path d="M46 148c2-28 22-42 50-42s48 14 50 42" fill="#D7DEE8" />
        <circle cx="96" cy="94" r="20" fill="#F4C9A0" />
        <path d="M78 90a18 18 0 0 1 36 0c0-9-8-16-18-16s-18 7-18 16z" fill="#8B8B8B" />
        <rect x="122" y="76" width="40" height="62" rx="8" fill="#fff" stroke="var(--risk)" stroke-width="3.5" />
        <rect x="130" y="86" width="24" height="6" rx="3" fill="var(--risk-soft)" />
        <rect x="130" y="98" width="18" height="6" rx="3" fill="var(--risk-soft)" />
        <circle cx="142" cy="118" r="9" fill="var(--risk)" />
        <path d="M142 113v6" stroke="#fff" stroke-width="2.5" stroke-linecap="round" />
        <circle cx="142" cy="123" r="1.4" fill="#fff" />
      </svg>`;
  return `
  <div class="easy-rsl-head">
    <div class="easy-rsl-badge sm">${T.msi(icon)}</div>
  </div>
  <div class="easy-rsl-headline">${headline}</div>
  <div class="easy-rsl-illustration">
    ${illustration}
    <div class="easy-rsl-illustration-badge">${T.msi(icon)}</div>
  </div>
  <div class="easy-rsl-highlight"><div class="k">${highlight.k}</div><div class="v">${hVal}</div><div class="note">${hNote}</div></div>
  <div class="easy-rsl-type"><span class="k">종류</span><span class="tag-pill">${typeTag}</span></div>
  <div class="easy-rsl-ai">
    <div class="hd">${T.msi("smart_toy")}<span>AI 요약</span></div>
    <p>${aiSummary}</p>
  </div>
  <div class="easy-rsl-checklist">
    ${checklist.map((c) => `<div class="row">${T.msi("check_circle")}<span>${c}</span></div>`).join("")}
  </div>
  <div class="easy-rsl-ask" data-nav="easy.voice">${T.msi("mic")}<span>${askLabel}</span>${T.msi("chevron_right", "chev")}</div>
  <div class="stack md" style="margin-top:var(--sp-xl)">
    ${T.button("확인 완료", { variant: "easy-rsl-confirm", nav: confirmNav, large: true, icon: "check" })}
  </div>`;
}

E("doc-result", "문서 읽기", "분석 결과", "22, 23", "분석 결과 — 위험도별 표현. Senior/Guardian이 공유하는 analysisResultBody()/.rsl-*는 손대지 않고, Easy 전용 easyResultBody()를 새로 사용.",
  "easyResultBody(kind, state, confirmNav) 호출 — 정보 밀도 낮춘 새 레이아웃(.easy-rsl-*), 내용은 전기요금 고지서 시나리오. 참고 이미지대로 상단바 전체를 위험도 색으로 틴트.",
  "위험 배지 → 한 문장 요약 → 핵심 정보 2줄 → 왜 그런지 → 할 일 2가지. 확인은 easy.doc-confirm으로 돌아온다.", ["안심", "주의", "위험"], (ctx, state) => {
    const tone = state === "위험" ? "dangerous" : state === "주의" ? "caution" : "safe";
    return `
  <div class="easy-rsl-${tone}">
    <div class="top-bar-tone"><button class="back" data-back>${T.msi("arrow_back")}</button><h1>분석 결과</h1><button class="right-action">${T.msi("menu")}</button></div>
    <div class="scr">${easyResultBody("doc", state, "easy.doc-confirm")}</div>
  </div>`; });

E("doc-confirm", "문서 읽기", "확인 완료", "24", "사용자가 결과를 확인했음을 기록.",
  "senior.doc-confirm 재사용.",
  "체크 아이콘 + \"기록에 저장됐어요\" + 홈으로.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">확인 완료</h2>
    <p class="body-sm" style="margin-bottom:24px">기록에 저장됐어요</p>
    ${T.button("홈으로", { variant: "accent", nav: "easy.home", large: true })}
  </div>`);

// ---------- 문자 확인 ----------
// 2026-08-28 — 사용자 제공 참고 이미지([최근 문자] 화면) 기반 재설계: "새
// 문자 확인하기" CTA를 없애고, 목록 자체가 진입점 — 항목을 누르면 분석 흐름
// (easy.msg-analyzing)으로 들어간다. 분석 전 상태라 위험도 배지는 없음(안심/
// 주의/위험은 분석 후에만 알 수 있음), 대신 발신자·미리보기·날짜만 보여준다.
E("msg-list", "문자 확인", "최근 문자", "27", "문자 분석 진입 — 참고 이미지의 [최근 문자] 화면 기반 재설계.",
  "senior.msg-list 대신 참고 이미지 그대로 — 별도 CTA 없이 목록 항목을 바로 눌러 분석을 시작한다.",
  "상단 '홈으로' 텍스트 백. 안내문 두 줄. 목록은 위험도 배지 없이 발신자/미리보기/날짜만(분석 전 상태이므로). " +
  "2026-08-29 — 문구 톤 정리(짧고 친근하게).", ["불러오는 중", "목록", "빈 목록"], (ctx, state) => `
  <div class="top-bar">
    <button class="back" style="width:auto" data-back>${T.msi("arrow_back")}홈으로</button>
  </div>
  <div class="scr">
    <div class="h1" style="margin-bottom:4px">최근 문자</div>
    <p class="body-sm" style="margin-bottom:var(--sp-lg)">최근 문자예요.<br>확인할 문자를 눌러주세요.</p>
    ${state === "불러오는 중" ? T.loadingState() : state === "빈 목록" ? T.emptyState("sms", "아직 확인한 문자가 없어요", "새 문자를 확인해보세요") : `
    <div class="stack">
      ${[
        { num: "114", label: "SKT 고객님", preview: "고객님의 반응이 없어 해지된 소액결제는 폐업 ARS를 통해 확인 후 조치하세요.", date: "6월 27일" },
        { num: "15880365", label: "", preview: "[신한투자증권] 본인확인 인증이 완료되었습니다.", date: "6월 26일" },
        { num: "15441151", label: "", preview: "[Web발신][광고]우리카드에서 보내드린 CU 쿠폰이 6/26일까지입니다.", date: "6월 26일" },
        { num: "15882588", label: "", preview: "[Web발신] hyojin33@bill36524.com으로 해외송금 도착 알림장이 전송됐습니다.", date: "6월 26일" },
      ].map((m) => T.listRow({ leftBadge: T.iconBadgeTint("sms", "primary", "sm"), title: m.label ? `${m.num} · ${m.label}` : m.num, sub: m.preview, right: `<span class="body-sm" style="flex:none;margin-left:8px">${m.date}</span>`, nav: "easy.msg-analyzing" })).join("")}
    </div>`}
  </div>`);

E("msg-analyzing", "문자 확인", "문자 분석 중", "27~28 사이", "AI 문자 분석 진행 상태.",
  "senior.msg-analyzing 재사용 — doc-analyzing과 같은 진행률 UI.",
  "문자 내용을 확인하는 중이라는 문구만 다르게. 2026-08-29 — 문구 톤 정리(짧고 친근하게).", null, (ctx) => `
  <div class="scr center">
    <div style="font-size:40px;font-weight:800;color:var(--primary);letter-spacing:-.5px">67%</div>
    <div class="confidence-bar" style="width:100%;max-width:260px;margin-top:16px"><i style="width:67%"></i></div>
    <p class="body" style="margin-top:20px;font-weight:700">온담이 열심히 분석하고 있어요</p>
    <p class="body-sm" style="margin-top:4px">문자를 확인하고 있어요</p>
  </div>`);

E("msg-result", "문자 확인", "문자 분석 결과", "28, 29, 30", "위험도별 문자 분석 결과 — Easy 전용 easyResultBody() 사용, 실제 문자 시나리오(택배 반송 사칭 사기 문자, 참고 이미지와 동일 시나리오) 내용.",
  "easyResultBody(kind, state, confirmNav) 호출 — doc-result와 같은 새 레이아웃(.easy-rsl-*), 내용만 문자에 맞게. 참고 이미지대로 상단바 전체를 위험도 색으로 틴트(보호자에게 전달하기 버튼은 사용자 요청으로 제외).",
  "위험 배지 → 한 문장 요약 → 발신 번호/위험 유형 → 왜 그런지 → 할 일 2가지. 확인은 easy.msg-guardian-notice로 이어진다.", ["안심", "주의", "위험"], (ctx, state) => {
    const tone = state === "위험" ? "dangerous" : state === "주의" ? "caution" : "safe";
    return `
  <div class="easy-rsl-${tone}">
    <div class="top-bar-tone"><button class="back" data-back>${T.msi("arrow_back")}</button><h1>진위 판별 결과</h1><button class="right-action">${T.msi("menu")}</button></div>
    <div class="scr">${easyResultBody("msg", state, "easy.msg-guardian-notice")}</div>
  </div>`; });

E("msg-guardian-notice", "문자 확인", "보호자 알림 안내", "32", "보호자에게 알림이 전송됐음을 안내.",
  "senior.msg-guardian-notice 재사용.",
  "\"OO님께 알려드렸어요\" + 홈으로.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">보호자에게 알렸어요</h2>
    <p class="body-sm" style="margin-bottom:24px">${ONDAM_DATA.guardianContact.name}님께 문자 내용을 전달했어요</p>
    ${T.button("홈으로", { variant: "accent", nav: "easy.home", large: true })}
  </div>`);

// ---------- 경로당 찾기 ----------
E("welfare-region", "경로당 찾기", "내 지역", "43", "지역 설정 후 검색 진입.",
  "senior.welfare-region 재사용.",
  "지역명을 크게, 검색 CTA 하나.", null, (ctx) => `
  ${T.topBar("내 지역")}
  <div class="scr center">
    ${T.iconBadgeTint("place", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">${ONDAM_DATA.seniorSelf.region}</h2>
    <p class="body-sm" style="margin-bottom:24px">현재 위치로 확인했어요</p>
    ${T.button("경로당 찾기", { variant: "accent", nav: "easy.welfare-search", large: true })}
  </div>`);

// 2026-08-28 — 사용자 요청 정정: "홈으로 말고 하단부분에 네이션바 추가해줘"
// — 위에서 넣었던 "← 홈으로" 상단 링크 대신, 하단 탭바(T.bottomNavEasy)를
// 추가한다. 이 화면 자체는 5개 루트 탭 중 하나가 아니라서 active는 지정하지 않는다.
E("welfare-search", "경로당 찾기", "경로당 검색", "44, 45, 46", "검색 진행 → 결과 표시.",
  "senior.welfare-search 재사용 + 하단에 Easy 탭바 추가.",
  "결과 없음일 때도 범위 넓히기로 다음 행동 제공.", ["불러오는 중", "결과 있음", "결과 없음"], (ctx, state) => `
  ${T.topBar("경로당 검색")}
  <div class="scr flush" style="padding:0 var(--sp-lg) var(--sp-xxl)">
    ${state === "불러오는 중" ? `<div style="padding:var(--sp-md) 0">${T.loadingState("경로당을 찾고 있어요")}</div>`
      : state === "결과 없음" ? T.emptyState("search_off", "근처에 경로당이 없어요", "검색 범위를 넓혀보세요", "범위 넓히기", "easy.welfare-search")
      : `<div style="padding:var(--sp-md) 0"><span class="body-sm">${ONDAM_DATA.seniorSelf.region} 근처 경로당 ${ONDAM_DATA.welfareCenters.length}곳</span></div>
    <div class="stack">${ONDAM_DATA.welfareCenters.map((w) => T.listRow({ leftBadge: T.iconBadgeTint("place", "secondary", "sm"), title: w.name, sub: `${w.addr} · ${w.open ? "운영 중" : "운영 종료"}`, nav: "easy.welfare-detail" })).join("")}</div>`}
  </div>
  ${T.bottomNavEasy("")}`);

// 2026-08-28 — 사용자 요청: 경로당 목록에서 항목을 누르면 "전화하기"뿐
// 아니라 "길 찾기"도 같이 뜨게. 실제 지도 연동은 없는 프로토타입이라 버튼만
// 두고, 전화걸기와 같은 확인 다이얼로그 패턴으로 통일.
E("welfare-detail", "경로당 찾기", "경로당 상세 (전화걸기·길찾기)", "47, 48", "상세 정보 + 전화 연결 + 길찾기.",
  "senior.welfare-detail 재사용, 전화하기 옆에 길찾기 버튼 추가.",
  "전화하기/길찾기 둘 다 확인 다이얼로그로 한 번 더 확인.", ["기본", "전화 확인", "길찾기 확인"], (ctx, state) => {
    const w = ONDAM_DATA.welfareCenters[0];
    return `
  ${T.topBar(w.name)}
  <div class="scr" style="position:relative;min-height:100%">
    ${T.card(`<div class="h1">${w.name}</div><div class="body-sm" style="margin-top:4px">${w.addr}</div><div class="body-sm" style="margin-top:6px"><span class="badge-dot">운영 중</span></div>${w.phoneNote ? `<div class="body-sm" style="margin-top:8px;color:var(--text-secondary)">${T.msi("info")} ${w.phoneNote}</div>` : ""}`)}
    <div class="stack md" style="margin-top:20px">
      ${T.button("전화하기", { variant: "accent", nav: "easy.welfare-detail", large: true, icon: "call", attrs: `data-state="전화 확인"` })}
      ${T.button("길 찾기", { variant: "secondary", nav: "easy.welfare-detail", large: true, icon: "directions", attrs: `data-state="길찾기 확인"` })}
    </div>
    ${state === "전화 확인" ? T.dialog(`${w.name}에 전화할까요?`, w.phone, `${T.button("취소", { variant: "secondary", nav: "easy.welfare-detail", attrs: `data-state="기본"` })}${T.button("전화하기", { variant: "accent", nav: "easy.welfare-detail", attrs: `data-state="기본"` })}`) : ""}
    ${state === "길찾기 확인" ? T.dialog(`${w.name}까지 길을 찾을까요?`, "지도 앱으로 이동해요", `${T.button("취소", { variant: "secondary", nav: "easy.welfare-detail", attrs: `data-state="기본"` })}${T.button("길찾기", { variant: "accent", nav: "easy.welfare-detail", attrs: `data-state="기본"` })}`) : ""}
  </div>`; });

// ---------- 말로 물어보기 ----------
E("voice", "말로 물어보기", "음성 비서", "17", "음성 명령 대체 입력 경로.",
  "senior.voice 재사용 — 큰 마이크 아이콘 + 퍼져나가는 링 pulsing.",
  "\"문서를 촬영해줘\"처럼 말하는 예시 문구. 2026-08-29 — 문구 톤 정리(짧고 친근하게).", null, (ctx) => `
  <div class="scr center" data-app="senior" data-easy="true">
    <div class="voice-listen"><span class="ring"></span><span class="ring r2"></span><span class="badge">${T.iconBadge("mic", "primary", "lg")}</span></div>
    <h2 class="h1" style="margin-top:16px">듣고 있어요</h2>
    <p class="body">"문서를 촬영해줘"처럼<br>말해보세요</p>
    <button class="btn ghost" data-back style="margin-top:20px">닫기</button>
  </div>`);

// ---------- 긴급 도움 ----------
// senior.emergency와 동일하게 배경에 easy.home을 그대로 깔고 시트만 덧씌운다
// — 다른 화면으로 착각하지 않도록.
E("emergency", "긴급 도움", "긴급 도움", "16", "긴급 상황 시 도움 요청 시트 — 배경에 Easy 홈이 보여야 다른 화면으로 착각하지 않는다.",
  "senior.emergency 재사용 — 배경만 easy.home으로 교체.",
  "112/119/110/120을 크고 색으로 구분, 취소는 항상 가능. " +
  "2026-08-29 — 사용자 요청으로 SOS 구성을 보호자 전화/119/112에서 112·119·110·120 4개 공공 긴급/상담 " +
  "번호로 교체(실제 Flutter 코드 emergency_help_sheet.dart와 동일 — senior.emergency와 같은 구성). " +
  "2026-08-31 — 이 화면(Easy)만 그 교체 이전 3버튼 구성(보호자 전화/119/112)으로 뒤쳐져 있던 걸 뒤늦게 맞춤. " +
  "112(경찰)·119(소방·구급)는 emergency(빨강) 톤, 110(정부민원안내)·120(다산콜센터)은 secondary 톤. " +
  "문구 톤 차이를 벌리기 위해 헤드라인은 짧고 친근하게 유지(Senior는 그대로 유지).", null, (ctx) => `
  <div class="scr flush" data-app="senior" style="position:relative;height:100%;overflow:hidden">
    <div aria-hidden="true">${SCREEN_MAP["easy.home"].render(ctx)}</div>
    ${T.sheet(`
      <div style="text-align:center">${T.iconBadge("crisis_alert", "emergency", "lg")}</div>
      <h2 class="h1" style="text-align:center;margin-top:14px">무슨 일이세요?</h2>
      <div class="stack md" style="margin-top:16px">
        ${T.button("112 신고하기", { variant: "emergency", icon: "local_police", large: true })}
        ${T.button("119 신고하기", { variant: "emergency", icon: "local_fire_department", large: true })}
        ${T.button("110 상담하기", { variant: "secondary", icon: "support_agent", large: true })}
        ${T.button("120 상담하기", { variant: "secondary", icon: "phone_in_talk", large: true })}
        <button class="btn ghost" data-back>취소</button>
      </div>`)}
  </div>`);

// ---------- 분석 기록 ----------
// 2026-08-28 — 참고 이미지의 [분석 기록] 화면 신규 반영: 하단 탭바의 "기록"
// 탭이 실제로 갈 곳이 없었음. 문서/문자 분석 기록 리스트 + 오늘 일정을
// senior.home의 today-row 패턴 그대로 재사용해 한 화면에.
// 2026-08-28 — 사용자 요청: 기록 탭 진입 시 고지서 통계를 맨 위에, 분석한
// 문서·문자 기록은 그 아래로. legacy-cleaned/senior-easy.html의 "나의 활동
// 통계"와 같은 6개월 전기요금(3~8월, 이번 달 87,500원) 데이터를 재사용해
// 두 산출물의 수치를 맞춘다. 고지서/요금 통계는 막대가 아니라 선 그래프로
// (이전 사용자 지시 그대로 유지).
E("records", "기록", "기록", "33", "Easy 앱의 기록 탭 — 고지서 통계를 맨 위에, 분석 기록·일정은 그 아래.",
  "senior.stats-fee의 T.feeHero/T.lineChart를 재사용 + 참고 이미지 기반 리스트로우(위험도 태그) + today-row 조합.",
  "고지서 통계(이번 달 요금 + 6개월 추이 선그래프) → 분석 기록(위험도 태그) → 일정 순으로 배치.", null, (ctx) => {
    const feePoints = [
      { v: 61000, m: "3월" }, { v: 58300, m: "4월" }, { v: 64900, m: "5월" },
      { v: 74200, m: "6월" }, { v: 92700, m: "7월" }, { v: 87500, m: "8월" },
    ];
    return `
  <div class="top-bar"><h1>기록</h1></div>
  <div class="scr">
    <div class="section-title">고지서 통계</div>
    ${T.feeHero("이번 달 전기요금", 87500, -5200)}
    <div style="height:14px"></div>
    ${T.card(`<div class="h-title" style="margin-bottom:10px">월별 전기요금 추이</div>${T.lineChart(feePoints, "m")}`)}

    <div class="row" style="margin-top:28px;margin-bottom:8px">${T.msi("history", "cal-icon")}<div class="section-title" style="margin:0">분석 기록</div></div>
    <div class="stack">
      ${T.listRow({ leftBadge: T.iconBadgeTint("description", "primary", "sm"), title: "전기요금 고지서", sub: "8/5 09:12", right: T.riskBadge("safe") })}
      ${T.listRow({ leftBadge: T.iconBadgeTint("sms", "primary", "sm"), title: "'저금리 대출 안내' 문자", sub: "8/4 15:40", right: T.riskBadge("dangerous") })}
    </div>

    <div class="row" style="margin-top:24px;margin-bottom:8px">${T.msi("calendar_today", "cal-icon")}<div class="section-title" style="margin:0">일정</div></div>
    <div class="stack">
      ${T.card(`<div class="today-row"><span class="time">10:00</span><div class="txt"><div class="ttl">보건소 무료 독감 예방접종</div><div class="loc">${T.msi("place")}${ONDAM_DATA.seniorSelf.region} 보건소</div></div></div>`)}
    </div>
  </div>
  ${T.bottomNavEasy("easy.records")}`; });

// ---------- 더보기 하위 (프로필/설정/알림/보호자연결) ----------
// 2026-08-28 — 사용자 요청: "초기에 로그인 화면부터 설정도 다 쉬운 모드로
// 변경하고". easy.more가 지금까지 senior.profile/settings/notif-settings/
// guardian-link로 그대로 연결되고 있어(entry.app이 "senior"라 Easy 확대
// 폰트/굵은 먹색 테두리를 못 받음) Easy 전용 화면으로 새로 만든다. 내용은
// senior.profile/settings-accessibility/notif-settings/guardian-link를
// 참고하되 그대로 베끼지 않고 Easy 컴포넌트(.card/.chip/.toggle, 전부
// [data-easy="true"] 스코프에서 이미 굵은 테두리+쨍한 색으로 스타일링됨)로
// 재구성. 하단 탭바 없는 뒤로가기 방식 — 홈/기록/정보/더보기만 탭바가
// 있는 기존 패턴 그대로.
E("profile", "더보기", "프로필", "50", "내 정보 확인 — Easy 모드에서도 글자 크기 유지.",
  "senior.profile과 같은 라벨-값 카드, Easy 톤으로.",
  "senior.profile을 그대로 쓰면 Easy 확대 폰트를 못 받아 별도로 만듦.", null, (ctx) => `
  ${T.topBar("프로필")}
  <div class="scr">
    ${T.card(`
      <div class="row between"><span class="body-sm">이름</span><span class="body" style="font-weight:800">${ONDAM_DATA.seniorSelf.name}</span></div>
      <div style="height:16px"></div>
      <div class="row between"><span class="body-sm">전화번호</span><span class="body" style="font-weight:800">010-1234-5678</span></div>
      <div style="height:16px"></div>
      <div class="row between"><span class="body-sm">태어난 해</span><span class="body" style="font-weight:800">1951</span></div>
    `)}
  </div>`);

E("settings", "더보기", "설정", "51,52", "글자 크기·음성 안내·언어를 한 화면에 모은 설정 — Easy 모드에서도 글자 크기 유지.",
  "senior.settings-accessibility/onboard-settings의 3항목(글자크기/음성안내/언어)을 드릴다운 없이 한 화면에.",
  "senior.settings를 그대로 쓰면 Easy 확대 폰트를 못 받아 별도로 만듦. 음성 안내 속도(1/1.2/1.5/2배)는 senior.onboard-settings에 이미 있는 패턴 재사용.", null, (ctx) => `
  ${T.topBar("설정")}
  <div class="scr">
    <div class="section-title">글자 크기</div>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">
      ${["보통", "크게", "아주 크게"].map((s) => `<button class="chip ${s === "크게" ? "active" : ""}" style="width:100%;justify-content:center">${s}</button>`).join("")}
    </div>

    <div class="section-title" style="margin-top:28px">음성 안내</div>
    ${T.card(`<div class="row"><div style="flex:1"><div class="h-title">음성으로 안내해드려요</div><div class="body-sm">화면을 읽어드려요</div></div><button class="toggle on"></button></div>`)}
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-top:12px">
      ${["1배", "1.2배", "1.5배", "2배"].map((v) => `<button class="chip ${v === "1배" ? "active" : ""}" style="width:100%;justify-content:center">${v}</button>`).join("")}
    </div>

    <div class="section-title" style="margin-top:28px">언어</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
      ${["한국어", "English", "日本語", "中文"].map((l) => `<button class="chip ${l === "한국어" ? "active" : ""}" style="width:100%;justify-content:center">${l}</button>`).join("")}
    </div>
  </div>`);

E("notif-settings", "더보기", "알림 설정", "56", "알림 종류별 on/off — Easy 모드에서도 글자 크기 유지.",
  "senior.notif-settings와 같은 구성(위험 알림은 항상 켜짐, 보호자 알림만 토글), Easy 톤으로.",
  "senior.notif-settings를 그대로 쓰면 Easy 확대 폰트를 못 받아 별도로 만듦.", ["on", "off"], (ctx, state) => `
  ${T.topBar("알림 설정")}
  <div class="scr">
    <div class="stack md">
      ${T.card(`<div class="row">${T.iconBadgeTint("warning", "danger")}<div style="flex:1"><span class="h-title">위험 알림</span></div><span class="caption">항상 켜짐</span></div>`)}
      ${T.card(`<div class="row">${T.iconBadgeTint("family_restroom", "primary")}<div style="flex:1"><span class="h-title">보호자 알림</span></div><button class="toggle ${state === "on" ? "on" : ""}" data-state="${state === "on" ? "off" : "on"}"></button></div>`)}
    </div>
  </div>`);

E("guardian-link", "더보기", "보호자 연결", "53", "보호자 연결 상태 관리 — Easy 모드에서도 글자 크기 유지.",
  "senior.guardian-link와 같은 구성(연결 카드 + 새 연결 + 해제), Easy 톤으로.",
  "senior.guardian-link를 그대로 쓰면 Easy 확대 폰트를 못 받아 별도로 만듦. 연결 해제는 확인 다이얼로그로 한 번 더. " +
  "2026-08-29 — 문구 톤 정리(짧고 친근하게).", ["기본", "해제 확인"], (ctx, state) => `
  ${T.topBar("보호자 연결")}
  <div class="scr" style="position:relative;min-height:100%">
    ${T.card(`<div class="row">${T.iconBadgeTint("person", "primary")}<div style="flex:1"><div class="h-title">${ONDAM_DATA.guardianContact.name}</div><div class="body-sm">연결됨 · 2026.06.01</div></div></div>`)}
    <div style="margin-top:24px">${T.button("새 보호자 연결하기", { variant: "accent", nav: "senior.qr-generate", large: true })}</div>
    <div style="margin-top:12px">${T.button("연결 해제하기", { variant: "secondary", nav: "easy.guardian-link", attrs: `data-state="해제 확인"` })}</div>
    ${state === "해제 확인" ? T.dialog(`${ONDAM_DATA.guardianContact.name}님과의 연결을 해제할까요?`, "해제하면 위험 알림을 못 받아요.", `${T.button("취소", { variant: "secondary", nav: "easy.guardian-link", attrs: `data-state="기본"` })}${T.button("해제하기", { variant: "emergency", nav: "easy.guardian-link", attrs: `data-state="기본"` })}`) : ""}
  </div>`);

// ---------- 정보 / 더보기 ----------
// 2026-08-28 — 사용자 요청: 하단 탭바의 "정보"/"더보기"가 senior.info/
// senior.more로 연결돼 있어 Easy 모드에서 들어가면 글자가 다시 작아지는
// 문제(entry.app이 "senior"라 [data-easy="true"] 토큰을 못 받음) → Easy
// 전용 화면을 새로 만들어 큰 글씨/큰 아이콘을 유지한다. 내용은 senior.info/
// senior.more와 같은 데이터(ONDAM_DATA.benefits, 메뉴 목록)를 그대로 재사용.
E("info", "정보", "정보 (맞춤 혜택)", "요청 목록 외", "하단 탭바 '정보' 탭 — Easy 모드에서도 글자 크기 유지.",
  "senior.info와 같은 ONDAM_DATA.benefits 데이터, Easy 카드 톤으로.",
  "senior.info를 그대로 쓰면 Easy 확대 폰트를 못 받아 하단 탭바에서만 별도로 만듦.", null, (ctx) => `
  <div class="top-bar"><h1>정보</h1></div>
  <div class="scr">
    <div class="body-sm" style="margin-bottom:16px">${ONDAM_DATA.seniorSelf.name}님을 위한 맞춤 정보예요</div>
    <div class="stack md">
      ${ONDAM_DATA.benefits.map((b) => T.card(`
        <div class="row" style="align-items:flex-start;gap:14px">
          ${T.iconBadge(b.icon, "primary")}
          <div style="flex:1">
            <div class="h-title" style="margin-bottom:4px">${b.title}</div>
            <div class="body-sm" style="margin-bottom:8px">${b.desc}</div>
            <span class="tag-pill">${b.tag}</span>
          </div>
        </div>`)).join("")}
    </div>
  </div>
  ${T.bottomNavEasy("easy.info")}`);

// 2026-08-28 — 사용자 요청: 세로 리스트 5줄이 화면에 비해 너무 휑해 보임
// ("너무 비어보여서 화면에 꽉꽉 채워서") → 2열 큰 타일 그리드로 재구성.
// 요금 통계(easy.records로 연결)를 다시 넣어 6칸(3행×2열)으로 꽉 채운다.
E("more", "더보기", "더보기", "49", "하단 탭바 '더보기' 탭 — Easy 모드에서도 글자 크기 유지, 2열 큰 타일로 화면을 꽉 채움.",
  "senior.more와 같은 메뉴 목록이지만 얇은 리스트 대신 2열 정사각 타일 그리드로.",
  "senior.more를 그대로 쓰면 Easy 확대 폰트를 못 받아 별도로 만듦. 세로 리스트가 화면 대비 휑해 보인다는 피드백으로 2열×3행 타일 그리드로 재구성, 요금 통계를 다시 넣어 6칸을 채움(easy.records로 연결).", null, (ctx) => `
  <div class="top-bar"><h1>더보기</h1></div>
  <div class="scr">
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
      ${[["person", "프로필", "easy.profile"], ["bar_chart", "요금 통계", "easy.records"], ["family_restroom", "보호자 연결", "easy.guardian-link"], ["settings", "설정", "easy.settings"], ["notifications", "알림 설정", "easy.notif-settings"], ["logout", "로그아웃", "easy.auth-login"]]
        .map(([icon, label, nav]) => `<div class="easy-tile" data-nav="${nav}">${T.iconBadge(icon, "primary", "lg")}<span class="lbl">${label}</span></div>`).join("")}
    </div>
  </div>
  ${T.bottomNavEasy("easy.more")}`);

// ---------- 온보딩 (보호자 연결) ----------
// 2026-08-28 — 사용자가 미리캔버스 온보딩 슬라이드 2장을 보여주며 "쉬운
// 모드로 바꿔줘" 요청 — 이 3화면은 온보딩 4~6단계(QR/보호자연결요청/완료)
// 담당. senior.onboard-qr/onboard-guardian/onboard-complete를 그대로
// 참고하되 Easy 컴포넌트(T.button large, T.card, T.iconBadge)로.
E("onboard-qr", "온보딩", "보호자 QR 안내", "11~12 사이", "온보딩 4단계 — 보호자 연결용 QR 표시, Easy 진입 흐름 전용.",
  "senior.onboard-qr과 동일 — 큰 헤드라인 아래 QR, 스캔 시 요청이 전달됨을 안내.",
  "senior.onboard-qr을 그대로 쓰면 Easy 확대 폰트를 못 받아 별도로 만듦. 다음/건너뛰기 둘 다 큰 버튼으로.", null, (ctx) => `
  <div class="scr center">
    <h1 class="h1" style="margin-top:8px">보호자에게 이 QR을<br>보여주세요</h1>
    <div style="margin-top:20px">${T.qrBox()}</div>
    <p class="body-sm" style="margin:16px 0 24px">보호자가 QR을 스캔하면<br>연결 요청이 도착해요</p>
    ${T.button("다음", { nav: "easy.onboard-guardian", large: true })}
    <button class="btn ghost" data-nav="easy.onboard-complete" style="margin-top:8px">건너뛰기</button>
  </div>`);

E("onboard-guardian", "온보딩", "보호자 연결 요청", "12", "온보딩 5단계 — 보호자가 보낸 연결 요청 수락/거절.",
  "senior.onboard-guardian과 동일 — 요청자 이름/관계/연락처를 카드로 보여줘 바로 판단 가능.",
  "ONDAM_DATA.guardianContact 데이터 재사용. 수락/거절 둘 다 큰 버튼으로 나란히.", null, (ctx) => `
  <div class="scr center">
    <h1 class="h1" style="margin-top:8px">보호자가 연결 요청을<br>보냈어요</h1>
    <div style="width:100%;margin-top:24px">
      ${T.card(`
        <div class="row" style="gap:12px">
          <div style="width:56px;height:56px;border-radius:50%;background:var(--primary-soft);color:var(--primary);display:flex;align-items:center;justify-content:center;font-size:20px;font-weight:800;flex:none">${ONDAM_DATA.guardianContact.name[0]}</div>
          <div style="flex:1;min-width:0">
            <div class="h-title">${ONDAM_DATA.guardianContact.name}</div>
            <div class="body-sm">${ONDAM_DATA.guardianContact.relation} · 010-****-5678</div>
          </div>
        </div>
      `)}
    </div>
    <div class="stack md" style="width:100%;margin-top:20px">
      ${T.button("수락", { variant: "accent", nav: "easy.onboard-complete", large: true })}
      ${T.button("거절", { variant: "secondary", nav: "easy.home", large: true })}
    </div>
  </div>`);

E("onboard-complete", "온보딩", "설정 완료", "13", "온보딩 마지막 단계 — 완료 확인, 바로 홈으로 진입.",
  "senior.onboard-complete의 컨페티 연출 대신, easy.doc-confirm 등에서 이미 쓰는 Easy 표준 완료 패턴(체크 배지+문구)으로 통일.",
  "체크 아이콘 + \"설정 완료!\" + \"기록에 저장됐어요\" + 홈으로 큰 버튼.", null, (ctx) => `
  <div class="scr center">
    ${T.iconBadge("check_circle", "secondary", "lg")}
    <h2 class="h1" style="margin-top:14px">설정 완료!</h2>
    <p class="body-sm" style="margin-bottom:24px">기록에 저장됐어요</p>
    ${T.button("홈으로", { variant: "accent", nav: "easy.home", large: true })}
  </div>`);
