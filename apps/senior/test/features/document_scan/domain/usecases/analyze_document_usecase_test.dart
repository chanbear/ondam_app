import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/domain/usecases/analyze_document_usecase.dart';

import '../fakes/fake_analysis_repository.dart';

void main() {
  late FakeAnalysisRepository repository;
  late AnalyzeDocumentUseCase useCase;
  final photo = CapturedPhoto(
    localPath: '/tmp/photo.jpg',
    capturedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = FakeAnalysisRepository();
    useCase = AnalyzeDocumentUseCase(repository);
  });

  test(
    'returns UnavailableFailure when no analysis backend exists (current Phase 4 state)',
    () async {
      repository.result = const Err(UnavailableFailure());

      final result = await useCase(photo, 'ko');

      expect(result, isA<Err<AnalysisResult>>());
      expect(
        (result as Err<AnalysisResult>).failure,
        isA<UnavailableFailure>(),
      );
      expect(repository.calls, [photo]);
    },
  );

  test(
    'propagates a real server failure distinctly from Unavailable',
    () async {
      repository.result = const Err(ServerFailure());

      final result = await useCase(photo, 'ko');

      expect((result as Err<AnalysisResult>).failure, isA<ServerFailure>());
      expect(result.failure, isNot(isA<UnavailableFailure>()));
    },
  );

  test('passes through a real AnalysisResult once a backend exists', () async {
    final analysisResult = AnalysisResult(
      id: 'a1',
      elderId: 'e1',
      type: AnalysisType.document,
      reliability: ReliabilityLevel.high,
      summary: '전기요금 고지서예요.',
      createdAt: DateTime(2026, 1, 1),
      structuredFields: const {'금액': '32,000원'},
    );
    repository.result = Ok(analysisResult);

    final result = await useCase(photo, 'ko');

    expect((result as Ok<AnalysisResult>).value, analysisResult);
  });
}
