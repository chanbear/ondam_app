import 'package:ondam_core/ondam_core.dart';

import '../entities/demographics.dart';
import '../repositories/demographics_repository.dart';

class SaveDemographicsUseCase {
  const SaveDemographicsUseCase(this._repository);

  final DemographicsRepository _repository;

  Future<Result<void>> call(Demographics demographics) {
    final age = demographics.age;
    if (age == null || age <= 0 || age > 120) {
      return Future.value(const Err(ValidationFailure('나이를 올바르게 입력해주세요.')));
    }
    if (demographics.gender == null) {
      return Future.value(const Err(ValidationFailure('성별을 선택해주세요.')));
    }
    return _repository.saveDemographics(demographics);
  }
}
