import 'package:ondam_core/ondam_core.dart';

import '../entities/camera_permission_status.dart';
import '../repositories/camera_repository.dart';

/// Triggers the OS permission prompt (first-time request only — the OS
/// silently returns the current status without prompting again if already
/// permanently denied; the UI must detect that case separately and offer a
/// settings-open path instead of calling this again).
class RequestCameraPermissionUseCase {
  const RequestCameraPermissionUseCase(this._repository);

  final CameraRepository _repository;

  Future<Result<CameraPermissionStatus>> call() =>
      _repository.requestPermission();
}
