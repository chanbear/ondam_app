/// Easy Mode enlargement factor for shared shell widgets (currently only
/// [AppBottomNavigation]) — implementation-plan.md §2 "쉬운 모드 배율 헬퍼".
/// Screen-specific Easy Mode content (e.g. `EasyModeHomeView`) uses its own
/// dedicated large-button widgets instead of scaling shared tokens.
abstract final class AppEasyMode {
  static const double navIconScale = 1.3;
  static const double navBarHeight = 80;
}
