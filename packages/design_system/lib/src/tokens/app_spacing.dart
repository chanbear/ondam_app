/// Spacing scale tokens — use instead of hardcoded padding/margin values.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;

  /// Modern Care 제안(2026-08-26)에서 추가된 단계 — 카드 내부 padding 등
  /// `sm`(8)과 `md`(16) 사이에 쓴다. 기존 `md` 이상 값은 재정의(rename)하지
  /// 않고 이 값만 삽입했다 — 스케일 전체를 shift하면 기존 호출부 전부에
  /// 영향이 가기 때문.
  static const double smMd = 12;

  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
