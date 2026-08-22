import 'package:ondam_core/ondam_core.dart';

import '../entities/location_permission_status.dart';
import '../repositories/location_repository.dart';

/// Reads the current location permission WITHOUT prompting the OS dialog —
/// mirrors `CheckCameraPermissionUseCase`.
class CheckLocationPermissionUseCase {
  const CheckLocationPermissionUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<LocationPermissionStatus>> call() =>
      _repository.checkPermission();
}
