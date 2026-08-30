import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
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

  Future<void> setVoiceGuideEnabled(bool enabled) async {
    state = state.copyWith(voiceGuideEnabled: enabled);
    await ref.read(localStorageProvider).setBool(_voiceGuideKey, enabled);
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
