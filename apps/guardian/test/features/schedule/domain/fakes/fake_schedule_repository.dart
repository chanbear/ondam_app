import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:ondam_models/ondam_models.dart';

/// Configurable fake — same pattern as `FakeAnalysisRepository`
/// (testing.md: Repository is faked, not hit over network).
class FakeScheduleRepository implements ScheduleRepository {
  Result<List<Schedule>> getSchedulesForElderResult = const Ok(<Schedule>[]);

  final List<String> getSchedulesForElderCalls = [];

  @override
  Future<Result<List<Schedule>>> getSchedulesForElder(String elderId) async {
    getSchedulesForElderCalls.add(elderId);
    return getSchedulesForElderResult;
  }
}
