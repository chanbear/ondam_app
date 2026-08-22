import 'package:ondam_core/ondam_core.dart';

import '../repositories/analysis_records_repository.dart';

/// ONDAM 2.0 요구사항 20/29 — "확인 완료"를 실제로 저장한다.
class ConfirmAnalysisResultUseCase {
  const ConfirmAnalysisResultUseCase(this._repository);

  final AnalysisRecordsRepository _repository;

  Future<Result<void>> call(String analysisResultId) =>
      _repository.confirm(analysisResultId);
}
