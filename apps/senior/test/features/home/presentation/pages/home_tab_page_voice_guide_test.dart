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
import 'package:ondam_senior/features/onboarding/presentation/providers/onboarding_status_provider.dart';
import 'package:ondam_senior/features/profile/domain/entities/profile.dart';
import 'package:ondam_senior/features/profile/presentation/providers/profile_provider.dart';
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

// `authStateChangesProvider`(→ 실제 네트워크가 없는 테스트용 fake Supabase)를
// 건드리면 재시도 타이머가 테스트 종료 뒤까지 남아 "Timer still pending"으로
// 실패한다 — 이 provider를 고정값으로 덮어써 그 경로를 아예 타지 않게 한다.
class _FixedOnboardingStatusNotifier extends OnboardingStatusNotifier {
  @override
  bool? build() => true;
}

// `NormalHomeView`의 인사말이 읽는 `profileProvider`도 같은 이유로
// 네트워크를 건드리지 않게 고정한다.
class _FixedProfileNotifier extends ProfileNotifier {
  @override
  Future<Profile?> build() async => null;
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

  testWidgets('꺼진 채로 홈에 들어왔다가 설정에서 켜면 즉시 안내를 읽는다', (tester) async {
    final fake = _FakeVoiceGuideService();
    final container = ProviderContainer(
      overrides: [
        voiceGuideServiceProvider.overrideWithValue(fake),
        accessibilityPrefsProvider.overrideWith(
          () => _FixedAccessibilityPrefsNotifier(false),
        ),
        onboardingStatusProvider.overrideWith(
          () => _FixedOnboardingStatusNotifier(),
        ),
        profileProvider.overrideWith(() => _FixedProfileNotifier()),
      ],
      // 테스트 환경엔 실제 네트워크가 없어 아직 못 찾은 provider가 실패하면
      // Riverpod 기본 재시도가 타이머를 계속 새로 예약해 "Timer still
      // pending"으로 테스트가 죽는다 — 이 컨테이너에서는 재시도 자체를 끈다.
      retry: (retryCount, error) => null,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeTabPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.spoken, isEmpty);

    await container
        .read(accessibilityPrefsProvider.notifier)
        .setVoiceGuideEnabled(true);
    await tester.pumpAndSettle();

    expect(fake.spoken, isNotEmpty);
  });
}
