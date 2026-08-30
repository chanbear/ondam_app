import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale/locale_provider.dart';
import '../../features/onboarding/presentation/providers/accessibility_prefs_provider.dart';
import 'tts_locale.dart';
import 'voice_guide_service.dart';

/// `dioClientProvider`/`localStorageProvider`와 같은 패턴 — 앱 전역에서
/// 공유하는 단일 서비스 인스턴스.
final voiceGuideServiceProvider = Provider<VoiceGuideService>((ref) {
  return VoiceGuideService();
});

/// 설정의 "음성 안내"가 켜져 있을 때만 [text]를 읽어준다 — 꺼져 있으면
/// 아무 것도 하지 않는다. 여러 화면이 반복 호출할 것이므로 core에 둔다.
Future<void> speakScreenGuide(WidgetRef ref, String text) async {
  final prefs = ref.read(accessibilityPrefsProvider);
  if (!prefs.voiceGuideEnabled) return;
  final service = ref.read(voiceGuideServiceProvider);
  await service.setLanguage(ttsLocaleTag(ref.read(localeControllerProvider)));
  await service.setSpeechRate(prefs.voiceRate.ttsRate);
  await service.speak(text);
}
