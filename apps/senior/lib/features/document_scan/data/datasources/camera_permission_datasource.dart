import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/camera_permission_status.dart';

/// Wraps `permission_handler`'s `Permission.camera` — the only place in
/// this feature allowed to know that package exists (api.md-equivalent
/// rule for non-Dio data sources, same pattern as auth's
/// `AuthRemoteDataSource` wrapping the Supabase SDK).
class CameraPermissionDataSource {
  Future<CameraPermissionStatus> check() async {
    final status = await Permission.camera.status;
    return _map(status);
  }

  Future<CameraPermissionStatus> request() async {
    final status = await Permission.camera.request();
    return _map(status);
  }

  CameraPermissionStatus _map(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited => CameraPermissionStatus.granted,
      PermissionStatus.permanentlyDenied =>
        CameraPermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => CameraPermissionStatus.restricted,
      PermissionStatus.denied ||
      PermissionStatus.provisional => CameraPermissionStatus.denied,
    };
  }
}
