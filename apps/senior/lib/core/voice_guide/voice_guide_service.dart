import 'package:flutter_tts/flutter_tts.dart';

/// `FlutterTts`를 감싸는 얇은 서비스 — "화면 내용을 자동으로 읽어주는"
/// 수동적 음성 안내(설정의 `accessibilityPrefsProvider.voiceGuideEnabled`)
/// 전용이다. `voice_assistant`의 대화형 STT/TTS(`VoiceInteractionView`)와는
/// 목적이 달라 그 위젯의 `FlutterTts` 인스턴스는 그대로 두고 건드리지 않는다.
class VoiceGuideService {
  final _tts = FlutterTts();

  Future<void> setLanguage(String localeTag) =>
      _guard(() => _tts.setLanguage(localeTag));

  Future<void> setSpeechRate(double rate) =>
      _guard(() => _tts.setSpeechRate(rate));

  /// 빈 문자열은 아무 것도 하지 않는다 — 읽을 안내 문구가 없는 화면에서
  /// 호출부가 매번 분기하지 않아도 되게 한다. 이전 발화가 남아있으면 먼저
  /// 멈추고 새로 읽는다(화면 전환 중 겹쳐 들리는 것 방지).
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _guard(() async {
      await _tts.stop();
      await _tts.speak(text);
    });
  }

  Future<void> stop() => _guard(_tts.stop);

  /// `VoiceGuideScaffold`가 이제 거의 모든 화면 진입/이탈마다 이 서비스를
  /// 호출한다 — 기기에 TTS 엔진/음성이 없거나(일부 기기), 테스트 환경처럼
  /// 플랫폼 채널이 없는 경우 `FlutterTts` 호출이 예외를 던질 수 있다.
  /// 음성 안내는 보조 기능이라 이 실패가 화면 전환이나 위젯 dispose 같은
  /// 핵심 동작을 막아서는 안 된다 — 조용히 무시한다.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // 음성 안내 실패는 무시 — 화면 기능에는 영향 없음.
    }
  }
}
