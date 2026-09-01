import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ondam_senior/app/app.dart';
import 'package:ondam_senior/core/easy_mode/easy_mode_provider.dart';
import 'package:ondam_senior/features/onboarding/domain/text_scale_level.dart';
import 'package:ondam_senior/features/onboarding/domain/voice_rate_level.dart';
import 'package:ondam_senior/features/onboarding/presentation/providers/accessibility_prefs_provider.dart';

/// BUG 35 회귀 테스트 — 설정의 글자 크기(TextScaleLevel)가 실제 앱의
/// MediaQuery.textScaler에 반영되는지 확인한다. 이전에는 scaleFactor가
/// 계산만 되고 어디에도 연결되지 않아 화면 글자 크기가 전혀 바뀌지
/// 않았다.
class _FixedAccessibilityPrefsNotifier extends AccessibilityPrefsNotifier {
  _FixedAccessibilityPrefsNotifier(this._fixed);

  final AccessibilityPrefs _fixed;

  @override
  AccessibilityPrefs build() => _fixed;
}

/// 쉬운 모드 글자 확대 회귀 테스트 — 화면별로 `easyMode ? styleA : styleB`
/// 개별 처리에 의존하면 그 처리가 빠진 위젯은 쉬운 모드를 켜도 전혀 안
/// 커진다(SettingsPage 일부 항목에서 실제로 발생했던 버그). 전역
/// textScaler에 배율을 얹는 방식이 모든 화면에 빠짐없이 적용되는지 확인한다.
class _FixedEasyModeNotifier extends EasyModeNotifier {
  _FixedEasyModeNotifier(this._fixed);

  final bool _fixed;

  @override
  bool build() => _fixed;
}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('기본 글자 크기(보통)는 배율 1.0으로 적용된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('온담 시작하기'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('휴대폰 번호로 시작하기'));
    expect(MediaQuery.of(context).textScaler.scale(10), 10);
  });

  testWidgets('글자 크기를 "크게"로 설정하면 배율 1.2가 앱 전체에 적용된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accessibilityPrefsProvider.overrideWith(
            () => _FixedAccessibilityPrefsNotifier(
              const AccessibilityPrefs(
                textScale: TextScaleLevel.large,
                voiceGuideEnabled: false,
                voiceRate: VoiceRateLevel.normal,
              ),
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('온담 시작하기'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('휴대폰 번호로 시작하기'));
    expect(MediaQuery.of(context).textScaler.scale(10), 12);
  });

  testWidgets('글자 크기를 "아주 크게"로 설정하면 배율 1.4가 앱 전체에 적용된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accessibilityPrefsProvider.overrideWith(
            () => _FixedAccessibilityPrefsNotifier(
              const AccessibilityPrefs(
                textScale: TextScaleLevel.extraLarge,
                voiceGuideEnabled: false,
                voiceRate: VoiceRateLevel.normal,
              ),
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('온담 시작하기'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('휴대폰 번호로 시작하기'));
    expect(MediaQuery.of(context).textScaler.scale(10), 14);
  });

  testWidgets('쉬운 모드를 켜면 글자 크기 배율에 추가로 곱해져 앱 전체에 적용된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accessibilityPrefsProvider.overrideWith(
            () => _FixedAccessibilityPrefsNotifier(
              const AccessibilityPrefs(
                textScale: TextScaleLevel.normal,
                voiceGuideEnabled: false,
                voiceRate: VoiceRateLevel.normal,
              ),
            ),
          ),
          easyModeProvider.overrideWith(() => _FixedEasyModeNotifier(true)),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('온담 시작하기'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('휴대폰 번호로 시작하기'));
    expect(MediaQuery.of(context).textScaler.scale(10), closeTo(11.5, 0.01));
  });
}
