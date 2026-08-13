import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/analysis/domain/usecases/get_analysis_records_usecase.dart';
import 'package:ondam_models/ondam_models.dart';

import '../fakes/fake_analysis_repository.dart';

void main() {
  test('elderId를 Repository에 그대로 전달한다', () async {
    final repository = FakeAnalysisRepository();
    final useCase = GetAnalysisRecordsUseCase(repository);

    await useCase('elder-1');

    expect(repository.getRecordsForElderCalls, ['elder-1']);
  });

  test('분석 데이터가 없으면 빈 목록을 그대로 반환한다(가짜 데이터로 채우지 않음)', () async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = const Ok(<AnalysisResult>[]);
    final useCase = GetAnalysisRecordsUseCase(repository);

    final result = await useCase('elder-1');

    expect(result, isA<Ok<List<AnalysisResult>>>());
    expect((result as Ok<List<AnalysisResult>>).value, isEmpty);
  });

  test('실제 AnalysisResult 목록을 그대로 반환한다', () async {
    final repository = FakeAnalysisRepository();
    final record = AnalysisResult(
      id: 'r1',
      elderId: 'elder-1',
      type: AnalysisType.message,
      reliability: ReliabilityLevel.high,
      summary: '요약',
      createdAt: DateTime(2026, 8, 1),
      riskLevel: RiskLevel.caution,
    );
    repository.getRecordsForElderResult = Ok([record]);
    final useCase = GetAnalysisRecordsUseCase(repository);

    final result = await useCase('elder-1');

    expect(result, isA<Ok<List<AnalysisResult>>>());
    expect((result as Ok<List<AnalysisResult>>).value, [record]);
  });

  test('Repository 실패(RLS 거부 등)를 그대로 전달한다', () async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = const Err(AuthFailure());
    final useCase = GetAnalysisRecordsUseCase(repository);

    final result = await useCase('elder-1');

    expect(result, isA<Err<List<AnalysisResult>>>());
  });
}
