import 'package:ondam_core/ondam_core.dart';

import '../entities/demographics.dart';
import '../repositories/demographics_repository.dart';

class GetMyDemographicsUseCase {
  const GetMyDemographicsUseCase(this._repository);

  final DemographicsRepository _repository;

  Future<Result<Demographics?>> call() => _repository.getMyDemographics();
}
