/// Minimum touch target tokens — use instead of hardcoding 48/56 across
/// button/icon-button widgets. `standard` is Material's accessibility floor;
/// `easy` is for Easy Mode / high-stakes CTAs (ui-principles.md "큰 터치
/// 영역"), matching the Phase 42-approved HTML prototype's `--touch-min`
/// (48px normal / 56px `[data-easy="true"]`).
abstract final class AppTouch {
  static const double standard = 48;
  static const double easy = 56;
}
