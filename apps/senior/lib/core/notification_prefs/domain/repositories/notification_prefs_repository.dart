import 'package:ondam_core/ondam_core.dart';

/// Whether the signed-in user wants a linked guardian notified when a
/// document/message analysis comes back risky ("보호자 알림" toggle in
/// notif-settings). Defaults to `true` server-side
/// (`20260831000001_users_guardian_notify_enabled.sql`) — a missing row/value
/// is treated as enabled, never as an error.
abstract class NotificationPrefsRepository {
  Future<Result<bool>> getGuardianNotifyEnabled();

  Future<Result<void>> setGuardianNotifyEnabled(bool enabled);
}
