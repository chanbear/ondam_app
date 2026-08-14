import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/domain/entities/notification_item.dart';
import 'package:ondam_guardian/features/notification/domain/usecases/get_my_notifications_usecase.dart';
import 'package:ondam_guardian/features/notification/domain/usecases/mark_notification_read_usecase.dart';
import 'package:ondam_guardian/features/notification/presentation/providers/notification_di_providers.dart';
import 'package:ondam_guardian/features/notification/presentation/providers/notifications_notifier.dart';

import '../../domain/fakes/fake_notification_repository.dart';

NotificationItem _item(String id, {DateTime? readAt}) {
  return NotificationItem(
    id: id,
    targetUserId: 'guardian-1',
    type: 'risk_alert',
    payload: const {'elder_id': 'elder-1', 'analysis_result_id': 'r1'},
    sentVia: 'push',
    createdAt: DateTime(2026, 8, 1),
    readAt: readAt,
  );
}

void main() {
  test('실제 NotificationItem 목록을 그대로 노출한다', () async {
    final repository = FakeNotificationRepository();
    repository.getMyNotificationsResult = Ok([_item('n1')]);
    final container = ProviderContainer(
      overrides: [
        getMyNotificationsUseCaseProvider.overrideWithValue(
          GetMyNotificationsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifications = await container.read(notificationsProvider.future);

    expect(notifications.single.id, 'n1');
  });

  test('markAsRead 성공 시 목록을 다시 불러온다', () async {
    final repository = FakeNotificationRepository();
    repository.getMyNotificationsResult = Ok([_item('n1')]);
    final container = ProviderContainer(
      overrides: [
        getMyNotificationsUseCaseProvider.overrideWithValue(
          GetMyNotificationsUseCase(repository),
        ),
        markNotificationReadUseCaseProvider.overrideWithValue(
          MarkNotificationReadUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(notificationsProvider.future);
    repository.getMyNotificationsResult = Ok([
      _item('n1', readAt: DateTime(2026, 8, 2)),
    ]);

    await container.read(notificationsProvider.notifier).markAsRead('n1');
    final notifications = await container.read(notificationsProvider.future);

    expect(repository.markAsReadCalls, ['n1']);
    expect(notifications.single.isRead, isTrue);
  });
}
