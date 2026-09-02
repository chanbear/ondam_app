import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/domain/repositories/analysis_repository.dart';

class FakeAnalysisRepository implements AnalysisRepository {
  Result<AnalysisResult> result = const Err(UnavailableFailure());

  /// 다중 문서(ONDAM 2.0 요구사항 11) 테스트용 — 설정돼 있으면 호출 순서대로
  /// 하나씩 꺼내 반환한다(사진마다 다른 결과를 주기 위함). 비어있으면 기존
  /// 처럼 [result] 하나를 매번 반환한다(하위 호환).
  List<Result<AnalysisResult>>? resultsQueue;

  final List<CapturedPhoto> calls = [];
  final List<String> languageCodeCalls = [];

  @override
  Future<Result<AnalysisResult>> analyzeDocument(
    CapturedPhoto photo,
    String languageCode,
  ) async {
    calls.add(photo);
    languageCodeCalls.add(languageCode);
    final queue = resultsQueue;
    if (queue != null && queue.isNotEmpty) {
      return queue.removeAt(0);
    }
    return result;
  }
}
