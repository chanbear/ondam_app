import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:ondam_models/ondam_models.dart';

/// Configurable fake — same pattern as `FakeConnectionRepository`
/// (testing.md: Repository is faked, not hit over network).
class FakeAnalysisRepository implements AnalysisRepository {
  Result<List<AnalysisResult>> getRecordsForElderResult = const Ok(
    <AnalysisResult>[],
  );

  final List<String> getRecordsForElderCalls = [];

  @override
  Future<Result<List<AnalysisResult>>> getRecordsForElder(
    String elderId,
  ) async {
    getRecordsForElderCalls.add(elderId);
    return getRecordsForElderResult;
  }
}
