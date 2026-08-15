import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/mic_permission_status.dart';

/// Wraps `permission_handler`'s `Permission.microphone` — the only place in
/// this feature allowed to know that package exists. Mirrors
/// `document_scan`'s `CameraPermissionDataSource`.
class MicPermissionDataSource {
  Future<MicPermissionStatus> check() async {
    final status = await Permission.microphone.status;
    return _map(status);
  }

  Future<MicPermissionStatus> request() async {
    final status = await Permission.microphone.request();
    return _map(status);
  }

  MicPermissionStatus _map(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited => MicPermissionStatus.granted,
      PermissionStatus.permanentlyDenied =>
        MicPermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => MicPermissionStatus.restricted,
      PermissionStatus.denied ||
      PermissionStatus.provisional => MicPermissionStatus.denied,
    };
  }
}
