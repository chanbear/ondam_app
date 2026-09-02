import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/locale/locale_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/voice_guide/tts_locale.dart';
import '../../../../core/voice_guide/voice_guide_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/text_scale_level.dart';
import '../../domain/voice_rate_level.dart';

/// 접근성 설정(글자크기/음성안내/음성 속도) — 순수 로컬 기기 설정이라
/// `LocalStorageService`에 저장한다(서버 `users` 테이블이 아직 없음 —
/// profile 관련 값과 다른 이유로 "지금은 로컬에만 둔다"가 아니라, 이
/// 값들은 애초에 기기별 설정이라 서버에 둘 필요가 없다). `easyModeProvider`와
/// 동일한 패턴(core/easy_mode 참고).
const _textScaleKey = 'accessibility_text_scale_level';
const _voiceGuideKey = 'accessibility_voice_guide_enabled';
const _voiceRateKey = 'accessibility_voice_rate_level';

class AccessibilityPrefs {
  const AccessibilityPrefs({
    required this.textScale,
    required this.voiceGuideEnabled,
    required this.voiceRate,
  });

  final TextScaleLevel textScale;
  final bool voiceGuideEnabled;
  final VoiceRateLevel voiceRate;

  AccessibilityPrefs copyWith({
    TextScaleLevel? textScale,
    bool? voiceGuideEnabled,
    VoiceRateLevel? voiceRate,
  }) {
    return AccessibilityPrefs(
      textScale: textScale ?? this.textScale,
      voiceGuideEnabled: voiceGuideEnabled ?? this.voiceGuideEnabled,
      voiceRate: voiceRate ?? this.voiceRate,
    );
  }
}

class AccessibilityPrefsNotifier extends Notifier<AccessibilityPrefs> {
  @override
  AccessibilityPrefs build() {
    _restore();
    return const AccessibilityPrefs(
      textScale: TextScaleLevel.normal,
      voiceGuideEnabled: false,
      voiceRate: VoiceRateLevel.normal,
    );
  }

  Future<void> _restore() async {
    final storage = ref.read(localStorageProvider);
    final scaleIndex = await storage.getInt(_textScaleKey, defaultValue: 0);
    final voiceGuide = await storage.getBool(_voiceGuideKey);
    final rateIndex = await storage.getInt(_voiceRateKey, defaultValue: 0);
    state = AccessibilityPrefs(
      textScale: TextScaleLevel
          .values[scaleIndex.clamp(0, TextScaleLevel.values.length - 1)],
      voiceGuideEnabled: voiceGuide,
      voiceRate: VoiceRateLevel
          .values[rateIndex.clamp(0, VoiceRateLevel.values.length - 1)],
    );
  }

  Future<void> setTextScale(TextScaleLevel level) async {
    state = state.copyWith(textScale: level);
    await ref.read(localStorageProvider).setInt(_textScaleKey, level.index);
  }

  // 토글을 켜는 순간 "지금부터 음성 안내를 지원합니다"를 바로 들려준다
  // (사용자 요청) — 이 지점부터 화면별 안내(VoiceGuideScaffold)가 시작된다는
  // 걸 눈이 아니라 귀로도 확인할 수 있게 한다. Notifier는 BuildContext가
  // 없어 `AppLocalizations.of(context)` 대신 로케일로 직접 조회하는
  // `lookupAppLocalizations`를 쓴다.
  Future<void> setVoiceGuideEnabled(bool enabled) async {
    state = state.copyWith(voiceGuideEnabled: enabled);
    await ref.read(localStorageProvider).setBool(_voiceGuideKey, enabled);
    if (!enabled) return;
    final l10n = lookupAppLocalizations(ref.read(localeControllerProvider));
    final service = ref.read(voiceGuideServiceProvider);
    await service.setLanguage(ttsLocaleTag(ref.read(localeControllerProvider)));
    await service.setSpeechRate(state.voiceRate.ttsRate);
    await service.speak(l10n.voiceGuideEnabledAnnouncement);
  }

  Future<void> setVoiceRate(VoiceRateLevel level) async {
    state = state.copyWith(voiceRate: level);
    await ref.read(localStorageProvider).setInt(_voiceRateKey, level.index);
  }
}

final accessibilityPrefsProvider =
    NotifierProvider<AccessibilityPrefsNotifier, AccessibilityPrefs>(
      AccessibilityPrefsNotifier.new,
    );
