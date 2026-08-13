import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

/// Guardian-side read access to `analysis_results` for a connected elder.
/// Implemented by `data/repositories/analysis_repository_impl.dart`, which
/// relies entirely on `analysis_results` RLS (elder must have an `accepted`
/// guardian_links row with the current user) — this repository does not
/// re-check connection status itself, the database does.
abstract class AnalysisRepository {
  /// All analysis records for [elderId], newest first. Empty list is a real
  /// outcome (no analysis backend has ever written a row yet — Phase 4), not
  /// an error.
  Future<Result<List<AnalysisResult>>> getRecordsForElder(String elderId);
}
