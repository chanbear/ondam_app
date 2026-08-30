/// 음성 안내 속도 4단계 — ui-prototype `S("onboard-settings")`/
/// `S("settings-accessibility")`의 1배/1.2배/1.5배/2배 칩과 맞춘다.
enum VoiceRateLevel {
  normal,
  fast,
  faster,
  fastest;

  /// 표시용 배율(1배 기준).
  double get multiplier => switch (this) {
    VoiceRateLevel.normal => 1.0,
    VoiceRateLevel.fast => 1.2,
    VoiceRateLevel.faster => 1.5,
    VoiceRateLevel.fastest => 2.0,
  };

  /// `flutter_tts`의 `setSpeechRate`는 플랫폼 공통 0.0~1.0 정규화 값이고
  /// 0.5가 통상적인 "보통" 속도다(패키지 문서 기준) — [multiplier]를 그
  /// 기준(0.5)에 곱해 유효 범위 안에서 배율을 근사한다.
  double get ttsRate => (multiplier * 0.5).clamp(0.0, 1.0);

  String get label => switch (this) {
    VoiceRateLevel.normal => '1배',
    VoiceRateLevel.fast => '1.2배',
    VoiceRateLevel.faster => '1.5배',
    VoiceRateLevel.fastest => '2배',
  };
}
