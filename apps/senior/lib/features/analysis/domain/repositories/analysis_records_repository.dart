import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

/// Senior-side read access to the current user's own `analysis_results`
/// rows. Unlike Guardian's `AnalysisRepository` (which takes an `elderId`
/// because a guardian may be connected to several elders), there is no
/// "which elder" concept here — the Senior app only ever shows the
/// signed-in user their own records, so this repository takes no id at all.
/// Implemented by `data/repositories/analysis_records_repository_impl.dart`,
/// which relies entirely on `analysis_results` RLS
/// (`analysis_results_select_elder`: `elder_id = auth.uid()`).
abstract class AnalysisRecordsRepository {
  /// All analysis records for the signed-in user, newest first. Empty list
  /// is a real outcome (no document/message has ever been analyzed yet),
  /// not an error.
  Future<Result<List<AnalysisResult>>> getMyRecords();

  /// Marks one analysis result as "확인 완료"(ONDAM 2.0 요구사항 20/29) by
  /// setting `confirmed_at` to now. Scoped to the signed-in user's own rows
  /// by RLS (`analysis_results_update_confirm_own`) and further restricted
  /// to only this column by a Postgres column privilege — no other column
  /// can be modified by any client role.
  Future<Result<void>> confirm(String analysisResultId);
}
