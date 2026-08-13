import 'package:ondam_core/ondam_core.dart';

import '../entities/camera_permission_status.dart';
import '../repositories/camera_repository.dart';

/// Reads the current camera permission WITHOUT prompting the OS dialog —
/// used when the camera screen is entered, to decide which state to show
/// before ever asking the user for anything.
class CheckCameraPermissionUseCase {
  const CheckCameraPermissionUseCase(this._repository);

  final CameraRepository _repository;

  Future<Result<CameraPermissionStatus>> call() =>
      _repository.checkPermission();
}
