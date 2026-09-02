import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/captured_photo.dart';
import '../repositories/analysis_repository.dart';

class AnalyzeDocumentUseCase {
  const AnalyzeDocumentUseCase(this._repository);

  final AnalysisRepository _repository;

  Future<Result<AnalysisResult>> call(
    CapturedPhoto photo,
    String languageCode,
  ) => _repository.analyzeDocument(photo, languageCode);
}
