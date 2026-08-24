import 'package:ondam_core/ondam_core.dart';

import '../../../../core/location/domain/entities/region.dart';
import '../entities/local_gov_office.dart';
import '../repositories/local_gov_office_repository.dart';

/// 지역이 없으면 조회 자체를 시도하지 않는다 — `SearchWelfareCentersUseCase`
/// 와 동일한 "지역이 있을 때만 조회" 패턴.
class SearchLocalGovOfficeUseCase {
  const SearchLocalGovOfficeUseCase(this._repository);

  final LocalGovOfficeRepository _repository;

  Future<Result<LocalGovOffice?>> call(Region? region) {
    if (region == null) {
      return Future.value(const Err(ValidationFailure('내 지역을 먼저 등록해주세요.')));
    }
    return _repository.search(region);
  }
}
