import 'package:ondam_core/ondam_core.dart';

import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Result<void>> call(String notificationId) =>
      _repository.markAsRead(notificationId);
}
