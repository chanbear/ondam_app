import 'package:ondam_core/ondam_core.dart';

import '../entities/region.dart';
import '../repositories/region_repository.dart';

class GetMyRegionUseCase {
  const GetMyRegionUseCase(this._repository);

  final RegionRepository _repository;

  Future<Result<Region?>> call() => _repository.getMyRegion();
}
