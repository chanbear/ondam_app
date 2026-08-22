/// Corner radius tokens — use instead of hardcoded BorderRadius values.
///
/// `md` (buttons) and `lg` (cards) match the Phase 42-approved HTML
/// prototype (14px / 20px). `sm`/`xl` aren't specified by the prototype and
/// are left as-is.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 24;
  static const double full = 999;
}
