import 'package:ondam_core/ondam_core.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../entities/benefit_service.dart';
import '../repositories/benefit_service_repository.dart';

/// 나이/성별/지역이 모두 있을 때만 검색을 시도한다 — "정보가 모두 채워졌을
/// 때만 검색" 요구사항을 usecase 레벨에서 보장한다(`SearchWelfareCentersUseCase`
/// 의 지역 검증 패턴과 동일).
class SearchBenefitServicesUseCase {
  const SearchBenefitServicesUseCase(this._repository);

  final BenefitServiceRepository _repository;

  Future<Result<List<BenefitService>>> call(
    Demographics? demographics,
    Region? region,
  ) {
    if (demographics == null || !demographics.isComplete) {
      return Future.value(
        const Err(ValidationFailure('나이와 성별을 먼저 입력해주세요.')),
      );
    }
    if (region == null) {
      return Future.value(const Err(ValidationFailure('내 지역을 먼저 등록해주세요.')));
    }
    return _repository.search(demographics, region);
  }
}
