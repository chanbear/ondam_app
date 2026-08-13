import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/sms_permission_status.dart';

/// Wraps `permission_handler`'s `Permission.sms` — the only place in this
/// feature allowed to know that package exists (api.md-equivalent rule for
/// non-Dio data sources, same pattern as `document_scan`'s
/// `CameraPermissionDataSource`). Android only — callers must not construct
/// this on other platforms.
class SmsPermissionDataSource {
  Future<SmsPermissionStatus> check() async {
    final status = await Permission.sms.status;
    return _map(status);
  }

  Future<SmsPermissionStatus> request() async {
    final status = await Permission.sms.request();
    return _map(status);
  }

  SmsPermissionStatus _map(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited => SmsPermissionStatus.granted,
      PermissionStatus.permanentlyDenied =>
        SmsPermissionStatus.permanentlyDenied,
      // SMS has no OS-level "restricted" concept on Android — treat it the
      // same as a plain retry-able denial rather than inventing a status
      // this platform never actually reports.
      PermissionStatus.restricted ||
      PermissionStatus.denied ||
      PermissionStatus.provisional => SmsPermissionStatus.denied,
    };
  }
}
