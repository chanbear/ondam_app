import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/voice_assistant/domain/entities/voice_intent.dart';

/// ONDAM 2.0V — 목적지가 분명한 Intent는 "이동하기" 확인 없이 즉시
/// 이동해야 하고, 목적지가 없는 unrecognized는 기존 확인/재시도 흐름을
/// 유지해야 한다.
void main() {
  test(
    '목적지가 있는 Intent(documentScan/messageCheck/emergencyHelp/welfareCenter)는 즉시 이동 대상이다',
    () {
      expect(VoiceIntent.documentScan.hasImmediateDestination, isTrue);
      expect(VoiceIntent.messageCheck.hasImmediateDestination, isTrue);
      expect(VoiceIntent.emergencyHelp.hasImmediateDestination, isTrue);
      expect(VoiceIntent.welfareCenter.hasImmediateDestination, isTrue);
    },
  );

  test('unrecognized는 즉시 이동 대상이 아니다 — 기존 확인/재시도 흐름을 유지한다', () {
    expect(VoiceIntent.unrecognized.hasImmediateDestination, isFalse);
  });
}
