import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/domain/entities/notification_item.dart';
import 'package:ondam_guardian/features/notification/domain/repositories/notification_repository.dart';

/// Configurable fake — same pattern as `FakeAnalysisRepository`
/// (testing.md: Repository is faked, not hit over network).
class FakeNotificationRepository implements NotificationRepository {
  Result<List<NotificationItem>> getMyNotificationsResult = const Ok(
    <NotificationItem>[],
  );
  Result<void> markAsReadResult = const Ok(null);

  int getMyNotificationsCallCount = 0;
  final List<String> markAsReadCalls = [];

  @override
  Future<Result<List<NotificationItem>>> getMyNotifications() async {
    getMyNotificationsCallCount++;
    return getMyNotificationsResult;
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    markAsReadCalls.add(notificationId);
    return markAsReadResult;
  }
}
