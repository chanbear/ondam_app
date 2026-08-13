import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/captured_photo.dart';

/// Submits a captured photo for AI analysis. As of Phase 4, no AI/analysis
/// backend exists (no Storage bucket, no Edge Function) — the implementation
/// returns `Err(UnavailableFailure())` deliberately, never a fabricated
/// [AnalysisResult] (Phase 4 rule: "Mock 분석 결과 생성 금지"). The contract
/// here is what Phase 6+'s real implementation will fulfill.
abstract class AnalysisRepository {
  Future<Result<AnalysisResult>> analyzeDocument(CapturedPhoto photo);
}
