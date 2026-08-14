import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/domain/entities/notification_item.dart';
import 'package:ondam_guardian/features/notification/domain/usecases/get_my_notifications_usecase.dart';

import '../fakes/fake_notification_repository.dart';

void main() {
  test('알림이 없으면 빈 목록을 그대로 반환한다(가짜 데이터로 채우지 않음)', () async {
    final repository = FakeNotificationRepository();
    final useCase = GetMyNotificationsUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<List<NotificationItem>>>());
    expect((result as Ok<List<NotificationItem>>).value, isEmpty);
    expect(repository.getMyNotificationsCallCount, 1);
  });

  test('실제 NotificationItem 목록을 그대로 반환한다', () async {
    final repository = FakeNotificationRepository();
    final item = NotificationItem(
      id: 'n1',
      targetUserId: 'guardian-1',
      type: 'risk_alert',
      payload: const {'elder_id': 'elder-1', 'analysis_result_id': 'r1'},
      sentVia: 'push',
      createdAt: DateTime(2026, 8, 1),
    );
    repository.getMyNotificationsResult = Ok([item]);
    final useCase = GetMyNotificationsUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<List<NotificationItem>>>());
    expect((result as Ok<List<NotificationItem>>).value, [item]);
  });

  test('Repository 실패를 그대로 전달한다', () async {
    final repository = FakeNotificationRepository();
    repository.getMyNotificationsResult = const Err(AuthFailure());
    final useCase = GetMyNotificationsUseCase(repository);

    final result = await useCase();

    expect(result, isA<Err<List<NotificationItem>>>());
  });
}
