import 'package:ondam_core/ondam_core.dart';

import '../../../../core/location/domain/entities/region.dart';
import '../entities/senior_center.dart';
import '../repositories/welfare_center_repository.dart';

/// 지역이 없으면 검색 자체를 시도하지 않는다 — "지역이 있을 때만 검색"
/// 요구사항(§11 테스트 항목)을 usecase 레벨에서 보장한다.
class SearchWelfareCentersUseCase {
  const SearchWelfareCentersUseCase(this._repository);

  final WelfareCenterRepository _repository;

  Future<Result<List<SeniorCenter>>> call(Region? region) {
    if (region == null) {
      return Future.value(const Err(ValidationFailure('내 지역을 먼저 등록해주세요.')));
    }
    return _repository.search(region);
  }
}
