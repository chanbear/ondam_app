import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/schedule/domain/repositories/schedule_repository.dart';

/// Configurable fake — same pattern as `FakeAnalysisRecordsRepository`
/// (testing.md: Repository is faked, not hit over network).
class FakeScheduleRepository implements ScheduleRepository {
  Result<List<Schedule>> getMySchedulesResult = const Ok(<Schedule>[]);
  int getMySchedulesCallCount = 0;

  Result<void> createScheduleResult = const Ok(null);
  final List<Map<String, Object?>> createScheduleCalls = [];

  Result<void> toggleCompletedResult = const Ok(null);
  final List<(String, bool)> toggleCompletedCalls = [];

  Result<void> deleteScheduleResult = const Ok(null);
  final List<String> deleteScheduleCalls = [];

  @override
  Future<Result<List<Schedule>>> getMySchedules() async {
    getMySchedulesCallCount++;
    return getMySchedulesResult;
  }

  @override
  Future<Result<void>> createSchedule({
    required String title,
    required DateTime scheduledAt,
    required bool isRecurring,
    int? recurrenceHour,
    int? recurrenceMinute,
  }) async {
    createScheduleCalls.add({
      'title': title,
      'scheduledAt': scheduledAt,
      'isRecurring': isRecurring,
      'recurrenceHour': recurrenceHour,
      'recurrenceMinute': recurrenceMinute,
    });
    return createScheduleResult;
  }

  @override
  Future<Result<void>> toggleCompleted(String id, bool completed) async {
    toggleCompletedCalls.add((id, completed));
    return toggleCompletedResult;
  }

  @override
  Future<Result<void>> deleteSchedule(String id) async {
    deleteScheduleCalls.add(id);
    return deleteScheduleResult;
  }
}
