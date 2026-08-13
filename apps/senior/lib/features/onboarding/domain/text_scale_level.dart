/// 글자 크기 3단계 — 기존 온담앱 관찰 사항(`ui-spec.md` Accessibility)을
/// 그대로 유지: 보통/크게/아주 크게.
enum TextScaleLevel {
  normal,
  large,
  extraLarge;

  double get scaleFactor => switch (this) {
    TextScaleLevel.normal => 1.0,
    TextScaleLevel.large => 1.2,
    TextScaleLevel.extraLarge => 1.4,
  };

  String get label => switch (this) {
    TextScaleLevel.normal => '보통',
    TextScaleLevel.large => '크게',
    TextScaleLevel.extraLarge => '아주 크게',
  };
}
