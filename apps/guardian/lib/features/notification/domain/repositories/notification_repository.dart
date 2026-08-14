import 'package:ondam_core/ondam_core.dart';

import '../entities/notification_item.dart';

/// Guardian-side read/write access to `notifications` for the current
/// (`target_user_id = auth.uid()`) user. RLS on that table is assumed to
/// already scope rows to their target — same division of responsibility as
/// `AnalysisRepository` (data-layer decides *how* rows are found, RLS
/// decides *which* rows are visible).
abstract class NotificationRepository {
  /// All notifications addressed to the current user, newest first. Empty
  /// list is a real outcome (no event has ever been sent), not an error.
  Future<Result<List<NotificationItem>>> getMyNotifications();

  Future<Result<void>> markAsRead(String notificationId);
}
