import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ondam_senior/core/voice_guide/voice_guide_provider.dart';
import 'package:ondam_senior/core/voice_guide/voice_guide_service.dart';
import 'package:ondam_senior/core/widgets/easy_analysis_result_view.dart';
import 'package:ondam_senior/features/onboarding/domain/text_scale_level.dart';
import 'package:ondam_senior/features/onboarding/domain/voice_rate_level.dart';
import 'package:ondam_senior/features/onboarding/presentation/providers/accessibility_prefs_provider.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

class _FakeVoiceGuideService extends VoiceGuideService {
  final spoken = <String>[];

  @override
  Future<void> setLanguage(String localeTag) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

class _FixedAccessibilityPrefsNotifier extends AccessibilityPrefsNotifier {
  @override
  AccessibilityPrefs build() => const AccessibilityPrefs(
    textScale: TextScaleLevel.normal,
    voiceGuideEnabled: true,
    voiceRate: VoiceRateLevel.normal,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('음성 안내가 켜져 있으면 결과 화면 진입 시 AI 요약을 읽는다', (tester) async {
    final fake = _FakeVoiceGuideService();
    final result = AnalysisResult(
      id: '1',
      elderId: 'elder-1',
      type: AnalysisType.document,
      reliability: ReliabilityLevel.high,
      summary: '이번 달 전기요금 고지서예요.',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceGuideServiceProvider.overrideWithValue(fake),
          accessibilityPrefsProvider.overrideWith(
            _FixedAccessibilityPrefsNotifier.new,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EasyAnalysisResultView(result: result, onAskByVoice: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.spoken, hasLength(1));
    expect(fake.spoken.single, contains('이번 달 전기요금 고지서예요.'));
  });
}
