import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ondam_senior/core/voice_guide/voice_guide_provider.dart';
import 'package:ondam_senior/core/voice_guide/voice_guide_service.dart';
import 'package:ondam_senior/features/home/presentation/pages/home_tab_page.dart';
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
  _FixedAccessibilityPrefsNotifier(this._enabled);
  final bool _enabled;

  @override
  AccessibilityPrefs build() => AccessibilityPrefs(
    textScale: TextScaleLevel.normal,
    voiceGuideEnabled: _enabled,
    voiceRate: VoiceRateLevel.normal,
  );
}

void main() {
  // 2026-08-30 — `onboardingStatusProvider`가 계정별 키로 스코프되며
  // `authStateChangesProvider`(→ `supabaseClientProvider`)를 watch하게
  // 됐다 — `HomeTabPage`를 그리는 위젯 테스트는 `widget_test.dart`와 같은
  // 더미 Supabase 초기화가 필요하다(세션 없음 → 기존 미스코프 키로 폴백,
  // 동작은 그대로).
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  Widget wrap(_FakeVoiceGuideService fake, bool voiceGuideEnabled) {
    return ProviderScope(
      overrides: [
        voiceGuideServiceProvider.overrideWithValue(fake),
        accessibilityPrefsProvider.overrideWith(
          () => _FixedAccessibilityPrefsNotifier(voiceGuideEnabled),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: HomeTabPage()),
      ),
    );
  }

  testWidgets('음성 안내가 켜져 있으면 홈 화면 진입 시 안내 문구를 읽는다', (tester) async {
    final fake = _FakeVoiceGuideService();
    await tester.pumpWidget(wrap(fake, true));
    await tester.pumpAndSettle();

    expect(fake.spoken, isNotEmpty);
  });

  testWidgets('음성 안내가 꺼져 있으면 아무 것도 읽지 않는다', (tester) async {
    final fake = _FakeVoiceGuideService();
    await tester.pumpWidget(wrap(fake, false));
    await tester.pumpAndSettle();

    expect(fake.spoken, isEmpty);
  });
}
