import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ondam_senior/core/voice_guide/voice_guide_provider.dart';
import 'package:ondam_senior/core/voice_guide/voice_guide_service.dart';
import 'package:ondam_senior/features/onboarding/domain/text_scale_level.dart';
import 'package:ondam_senior/features/onboarding/domain/voice_rate_level.dart';
import 'package:ondam_senior/features/onboarding/presentation/providers/accessibility_prefs_provider.dart';

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
  _FixedAccessibilityPrefsNotifier(this._fixed);
  final AccessibilityPrefs _fixed;

  @override
  AccessibilityPrefs build() => _fixed;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<WidgetRef> pumpRef(
    WidgetTester tester,
    _FakeVoiceGuideService fake,
    bool voiceGuideEnabled,
  ) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceGuideServiceProvider.overrideWithValue(fake),
          accessibilityPrefsProvider.overrideWith(
            () => _FixedAccessibilityPrefsNotifier(
              AccessibilityPrefs(
                textScale: TextScaleLevel.normal,
                voiceGuideEnabled: voiceGuideEnabled,
                voiceRate: VoiceRateLevel.normal,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return capturedRef;
  }

  testWidgets('voiceGuideEnabled이 꺼져 있으면 speak를 호출하지 않는다', (tester) async {
    final fake = _FakeVoiceGuideService();
    final ref = await pumpRef(tester, fake, false);

    await speakScreenGuide(ref, '안내 문구');

    expect(fake.spoken, isEmpty);
  });

  testWidgets('voiceGuideEnabled이 켜져 있으면 문구를 읽는다', (tester) async {
    final fake = _FakeVoiceGuideService();
    final ref = await pumpRef(tester, fake, true);

    await speakScreenGuide(ref, '안내 문구');

    expect(fake.spoken, ['안내 문구']);
  });
}
