import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../repositories/analysis_records_repository.dart';

class GetMyAnalysisRecordsUseCase {
  const GetMyAnalysisRecordsUseCase(this._repository);

  final AnalysisRecordsRepository _repository;

  Future<Result<List<AnalysisResult>>> call() => _repository.getMyRecords();
}
