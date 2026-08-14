import 'package:ondam_core/ondam_core.dart';

import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class GetMyNotificationsUseCase {
  const GetMyNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Result<List<NotificationItem>>> call() =>
      _repository.getMyNotifications();
}
