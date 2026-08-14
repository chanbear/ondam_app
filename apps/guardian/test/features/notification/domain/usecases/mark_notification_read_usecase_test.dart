import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/domain/usecases/mark_notification_read_usecase.dart';

import '../fakes/fake_notification_repository.dart';

void main() {
  test('notificationId를 Repository에 그대로 전달한다', () async {
    final repository = FakeNotificationRepository();
    final useCase = MarkNotificationReadUseCase(repository);

    await useCase('n1');

    expect(repository.markAsReadCalls, ['n1']);
  });

  test('Repository 실패를 그대로 전달한다', () async {
    final repository = FakeNotificationRepository();
    repository.markAsReadResult = const Err(ServerFailure());
    final useCase = MarkNotificationReadUseCase(repository);

    final result = await useCase('n1');

    expect(result, isA<Err<void>>());
  });
}
