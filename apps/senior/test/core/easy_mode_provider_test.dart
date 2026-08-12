import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ondam_senior/core/easy_mode/easy_mode_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('easy mode defaults to off', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(easyModeProvider), isFalse);
  });

  test('toggle flips state and persists it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(easyModeProvider.notifier).toggle();

    expect(container.read(easyModeProvider), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('easy_mode_enabled'), isTrue);
  });
}
