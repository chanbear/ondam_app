// Mirrors the current screen's title into #kioskBar's label. Everything
// else about navigation (render/highlightNav/etc.) is untouched app.js.
(function () {
  const _origRender = render;
  render = function () {
    _origRender();
    const entry = SCREEN_MAP[STATE.screenId];
    const el = document.getElementById("kioskTitle");
    if (el && entry) el.textContent = entry.title;
  };
})();

// QR/공개 링크로 들어온 방문자는 앱 선택 화면(#landing)이나 enterApp()의
// 기본 진입점(senior.home)이 아니라, 실제 첫 방문자가 보는 로그인 화면부터
// 시작해 전화번호 입력 등 온보딩 흐름을 그대로 눌러볼 수 있어야 한다
// (사용자 요청 2026-08-30). data-nav 클릭 흐름 자체는 건드리지 않는다 —
// 시작 화면만 바꾼다.
enterApp("senior");
goTo("senior.auth-login", { replace: true });
