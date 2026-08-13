import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/domain/repositories/analysis_repository.dart';

class FakeAnalysisRepository implements AnalysisRepository {
  Result<AnalysisResult> result = const Err(UnavailableFailure());

  final List<CapturedPhoto> calls = [];

  @override
  Future<Result<AnalysisResult>> analyzeDocument(CapturedPhoto photo) async {
    calls.add(photo);
    return result;
  }
}
