import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/analysis/domain/repositories/analysis_records_repository.dart';

/// Configurable fake — same pattern as Guardian's `FakeAnalysisRepository`
/// (testing.md: Repository is faked, not hit over network).
class FakeAnalysisRecordsRepository implements AnalysisRecordsRepository {
  Result<List<AnalysisResult>> getMyRecordsResult = const Ok(
    <AnalysisResult>[],
  );

  int getMyRecordsCallCount = 0;

  Result<void> confirmResult = const Ok(null);
  final List<String> confirmCalls = [];

  @override
  Future<Result<List<AnalysisResult>>> getMyRecords() async {
    getMyRecordsCallCount++;
    return getMyRecordsResult;
  }

  @override
  Future<Result<void>> confirm(String analysisResultId) async {
    confirmCalls.add(analysisResultId);
    return confirmResult;
  }
}
