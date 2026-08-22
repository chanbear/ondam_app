import 'package:ondam_core/ondam_core.dart';

import '../entities/region.dart';
import '../repositories/region_repository.dart';

class SaveRegionUseCase {
  const SaveRegionUseCase(this._repository);

  final RegionRepository _repository;

  Future<Result<void>> call(Region region) {
    if (region.sido.trim().isEmpty ||
        region.sigungu.trim().isEmpty ||
        region.dong.trim().isEmpty) {
      return Future.value(const Err(ValidationFailure('지역을 모두 입력해주세요.')));
    }
    return _repository.saveRegion(
      Region(
        sido: region.sido.trim(),
        sigungu: region.sigungu.trim(),
        dong: region.dong.trim(),
      ),
    );
  }
}
