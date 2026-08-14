import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/notification_item.dart';
import 'notification_di_providers.dart';

/// `notifications` rows addressed to the current user (home/notification
/// tab). Separate from `AnalysisRecordsNotifier` — that one derives a risk
/// list from `analysis_results` per elder; this one is the actual Push/
/// notification event log (technical-decisions.md §1-4/§1-10).
class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    final result = await ref.read(getMyNotificationsUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<void> markAsRead(String notificationId) async {
    final result = await ref
        .read(markNotificationReadUseCaseProvider)
        .call(notificationId);
    if (result is Ok<void>) {
      ref.invalidateSelf();
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
      NotificationsNotifier.new,
    );
