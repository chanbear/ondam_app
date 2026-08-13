import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../repositories/analysis_repository.dart';

class GetAnalysisRecordsUseCase {
  const GetAnalysisRecordsUseCase(this._repository);

  final AnalysisRepository _repository;

  Future<Result<List<AnalysisResult>>> call(String elderId) =>
      _repository.getRecordsForElder(elderId);
}
