import 'package:ondam_core/ondam_core.dart';

import '../entities/region.dart';
import '../repositories/location_repository.dart';

/// "현재 위치 사용" — assumes permission is already granted; the caller
/// (presentation) is responsible for checking/requesting permission first,
/// same division of responsibility as camera's capture flow.
class GetCurrentRegionUseCase {
  const GetCurrentRegionUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<Region>> call() => _repository.getCurrentRegion();
}
