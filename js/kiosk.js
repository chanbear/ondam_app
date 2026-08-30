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
