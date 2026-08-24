import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

/// Guardian-side read access to `schedules` for a connected elder.
/// Implemented by `data/repositories/schedule_repository_impl.dart`, which
/// relies entirely on `schedules` RLS (elder must have an `accepted`
/// guardian_links row with the current user) — this repository does not
/// re-check connection status itself, the database does. Guardian never
/// creates/edits/deletes a schedule (읽기 전용, feature-spec.md MODIFY-9).
abstract class ScheduleRepository {
  /// All schedules for [elderId], soonest first. Empty list is a real
  /// outcome (no schedule created yet), not an error.
  Future<Result<List<Schedule>>> getSchedulesForElder(String elderId);
}
