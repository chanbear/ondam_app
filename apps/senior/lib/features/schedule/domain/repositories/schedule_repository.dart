import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

/// Senior-side full CRUD access to the current user's own `schedules` rows.
/// There is no "which elder" concept here (같은 이유로 `AnalysisRecordsRepository`도
/// elderId를 받지 않는다) — the Senior app only ever manages the signed-in
/// user's own schedules. Implemented by
/// `data/repositories/schedule_repository_impl.dart`, which relies entirely
/// on `schedules` RLS (elder_id = auth.uid()).
abstract class ScheduleRepository {
  /// All schedules for the signed-in user, soonest first. Empty list is a
  /// real outcome (no schedule created yet), not an error.
  Future<Result<List<Schedule>>> getMySchedules();

  /// [recurrenceHour]/[recurrenceMinute]는 [isRecurring]이 true일 때만 넘긴다
  /// — 유효성 검증은 이 메서드를 호출하는 `CreateScheduleUseCase`의 책임.
  Future<Result<void>> createSchedule({
    required String title,
    required DateTime scheduledAt,
    required bool isRecurring,
    int? recurrenceHour,
    int? recurrenceMinute,
  });

  Future<Result<void>> toggleCompleted(String id, bool completed);

  Future<Result<void>> deleteSchedule(String id);
}
