import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ondam_guardian/core/locale/locale_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('기본 언어는 한국어다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), const Locale('ko'));
  });

  test('언어를 바꾸면 상태와 저장소가 모두 갱신된다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('ja'));

    expect(container.read(localeControllerProvider), const Locale('ja'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'ja');
  });

  test('앱 재시작 후에도 저장된 언어를 복원한다', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // provider를 먼저 read해 build()(따라서 _restore())를 시작시킨 뒤,
    // SharedPreferences의 비동기 체인(getInstance → getString)이 끝날
    // 때까지 이벤트 큐를 비운다.
    container.read(localeControllerProvider);
    await pumpEventQueue();

    expect(container.read(localeControllerProvider), const Locale('en'));
  });
}
