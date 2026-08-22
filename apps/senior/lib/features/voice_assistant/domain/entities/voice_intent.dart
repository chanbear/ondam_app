/// A recognized voice command, mapped to one of the small set of onboard
/// features the voice assistant can trigger in this phase
/// (technical-decisions.md §5-2 OPEN QUESTIONS 10 DECIDED — client keyword
/// matching only, no server AI).
enum VoiceIntent {
  documentScan,
  messageCheck,
  emergencyHelp,
  welfareCenter,
  unrecognized,
}

/// ONDAM 2.0V — 목적지가 분명한 명령은 "이동하기" 확인 없이 바로 이동한다.
/// [VoiceIntent.unrecognized]처럼 목적지가 없는 경우만 기존 확인/재시도
/// 화면을 유지한다. 새 목적지를 추가할 때는 여기에도 함께 추가해야 즉시
/// 이동 대상이 된다 — 기본값(추가하지 않음)은 "확인 단계 유지"이므로,
/// 목적지가 실제로 연결되기 전까지는 안전하게 unrecognized와 동일하게
/// 취급된다.
extension VoiceIntentNavigation on VoiceIntent {
  bool get hasImmediateDestination => switch (this) {
    VoiceIntent.documentScan ||
    VoiceIntent.messageCheck ||
    VoiceIntent.emergencyHelp ||
    VoiceIntent.welfareCenter => true,
    VoiceIntent.unrecognized => false,
  };
}
