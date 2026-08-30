import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/core/voice_guide/voice_guide_service.dart';

void main() {
  // FlutterTts()의 생성자가 MethodChannel.setMethodCallHandler()를
  // 호출하는데, 이는 바인딩이 초기화돼 있어야 한다 — 순수 test()에서는
  // 명시적으로 초기화해줘야 한다(testWidgets()는 자동으로 해준다).
  TestWidgetsFlutterBinding.ensureInitialized();

  test('빈 문자열은 TTS 엔진을 건드리지 않고 조용히 끝난다', () async {
    final service = VoiceGuideService();
    await service.speak('');
  });
}
