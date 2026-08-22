import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/voice_assistant/domain/entities/voice_intent.dart';
import 'package:ondam_senior/features/voice_assistant/domain/usecases/classify_voice_intent_usecase.dart';

void main() {
  const useCase = ClassifyVoiceIntentUseCase();

  test('문서 관련 발화는 documentScan으로 분류한다', () {
    expect(useCase('문서 찍어줘'), VoiceIntent.documentScan);
    expect(useCase('서류 촬영하고 싶어'), VoiceIntent.documentScan);
  });

  test('문자 관련 발화는 messageCheck로 분류한다', () {
    expect(useCase('문자 확인해줘'), VoiceIntent.messageCheck);
    expect(useCase('메시지 좀 봐줘'), VoiceIntent.messageCheck);
  });

  test('긴급 관련 발화는 emergencyHelp로 분류한다', () {
    expect(useCase('긴급 도움'), VoiceIntent.emergencyHelp);
    expect(useCase('도와줘'), VoiceIntent.emergencyHelp);
  });

  test('경로당 관련 발화는 welfareCenter로 분류한다', () {
    expect(useCase('경로당'), VoiceIntent.welfareCenter);
    expect(useCase('경로당 찾아줘'), VoiceIntent.welfareCenter);
    expect(useCase('근처 경로당'), VoiceIntent.welfareCenter);
    expect(useCase('주변 경로당'), VoiceIntent.welfareCenter);
  });

  test('빈 문자열(무음)은 unrecognized로 분류한다', () {
    expect(useCase(''), VoiceIntent.unrecognized);
    expect(useCase('   '), VoiceIntent.unrecognized);
  });

  test('키워드와 무관한 발화는 unrecognized로 분류한다', () {
    expect(useCase('오늘 날씨 어때'), VoiceIntent.unrecognized);
  });
}
