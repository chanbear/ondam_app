import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/notification_prefs/presentation/providers/notification_prefs_di_providers.dart';
import 'package:ondam_senior/core/notification_prefs/presentation/providers/notification_prefs_provider.dart';

import '../../domain/fakes/fake_notification_prefs_repository.dart';

void main() {
  test('행/컬럼 값을 그대로 읽어온다', () async {
    final repository = FakeNotificationPrefsRepository();
    repository.getGuardianNotifyEnabledResult = const Ok(false);
    final container = ProviderContainer(
      overrides: [
        notificationPrefsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final value = await container.read(guardianNotifyEnabledProvider.future);

    expect(value, false);
    expect(repository.getCalls, 1);
  });

  test('저장 성공 후에는 요청 값을 그대로 믿지 않고 서버에서 다시 조회한다(저장 후 재조회)', () async {
    final repository = FakeNotificationPrefsRepository();
    repository.getGuardianNotifyEnabledResult = const Ok(true);
    final container = ProviderContainer(
      overrides: [
        notificationPrefsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(guardianNotifyEnabledProvider.future);
    expect(repository.getCalls, 1);

    repository.getGuardianNotifyEnabledResult = const Ok(false);
    final result = await container
        .read(guardianNotifyEnabledProvider.notifier)
        .setEnabled(false);

    expect(result, isA<Ok<void>>());
    expect(repository.savedValue, false);
    expect(repository.getCalls, greaterThanOrEqualTo(2));
    expect(container.read(guardianNotifyEnabledProvider).value, false);
  });

  test('저장 실패 시에는 재조회하지 않는다', () async {
    final repository = FakeNotificationPrefsRepository();
    repository.getGuardianNotifyEnabledResult = const Ok(true);
    repository.setGuardianNotifyEnabledResult = const Err(ServerFailure());
    final container = ProviderContainer(
      overrides: [
        notificationPrefsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(guardianNotifyEnabledProvider.future);
    final callsAfterInitialLoad = repository.getCalls;

    final result = await container
        .read(guardianNotifyEnabledProvider.notifier)
        .setEnabled(false);

    expect(result, isA<Err<void>>());
    expect(repository.getCalls, callsAfterInitialLoad);
  });
}
