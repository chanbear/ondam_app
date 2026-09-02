import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/captured_photo.dart';

/// Submits a captured photo for AI analysis. The real implementation
/// (`AnalysisRepositoryImpl`) uploads the photo to the `document-photos`
/// Storage bucket and calls the `analyze-document` Edge Function — an
/// `UnavailableFailure` is still a possible, honest result (e.g. no AI
/// provider secret configured in this environment), never a fabricated
/// [AnalysisResult] (Phase 4 rule: "Mock 분석 결과 생성 금지").
abstract class AnalysisRepository {
  Future<Result<AnalysisResult>> analyzeDocument(
    CapturedPhoto photo,
    String languageCode,
  );
}
