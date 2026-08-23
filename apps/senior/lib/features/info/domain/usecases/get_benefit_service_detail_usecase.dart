import 'package:ondam_core/ondam_core.dart';

import '../entities/benefit_service.dart';
import '../entities/benefit_service_detail.dart';
import '../repositories/benefit_service_repository.dart';

class GetBenefitServiceDetailUseCase {
  const GetBenefitServiceDetailUseCase(this._repository);

  final BenefitServiceRepository _repository;

  Future<Result<BenefitServiceDetail>> call(
    String id,
    BenefitServiceSource source,
  ) {
    if (id.trim().isEmpty) {
      return Future.value(const Err(ValidationFailure('잘못된 혜택 정보예요.')));
    }
    return _repository.getDetail(id, source);
  }
}
