import 'package:ondam_core/ondam_core.dart';

import '../entities/location_permission_status.dart';
import '../repositories/location_repository.dart';

/// Triggers the actual OS permission prompt — mirrors
/// `RequestCameraPermissionUseCase`.
class RequestLocationPermissionUseCase {
  const RequestLocationPermissionUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<LocationPermissionStatus>> call() =>
      _repository.requestPermission();
}
