import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/domain/usecases/check_message_risk_usecase.dart';

import '../fakes/fake_message_risk_repository.dart';

void main() {
  late FakeMessageRiskRepository repository;
  late CheckMessageRiskUseCase useCase;
  final message = SmsMessage(
    sender: '010-1234-5678',
    body: '[Web발신] 계좌가 정지되었습니다. 즉시 확인 바랍니다.',
    receivedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = FakeMessageRiskRepository();
    useCase = CheckMessageRiskUseCase(repository);
  });

  test(
    'returns UnavailableFailure when no risk-analysis backend exists (current Phase 7 state)',
    () async {
      repository.result = const Err(UnavailableFailure());

      final result = await useCase(message);

      expect(result, isA<Err<AnalysisResult>>());
      expect(
        (result as Err<AnalysisResult>).failure,
        isA<UnavailableFailure>(),
      );
      expect(repository.calls, [message]);
    },
  );

  test(
    'propagates a real server failure distinctly from Unavailable',
    () async {
      repository.result = const Err(ServerFailure());

      final result = await useCase(message);

      expect((result as Err<AnalysisResult>).failure, isA<ServerFailure>());
      expect(result.failure, isNot(isA<UnavailableFailure>()));
    },
  );

  test('passes through a real AnalysisResult once a backend exists', () async {
    final analysisResult = AnalysisResult(
      id: 'a1',
      elderId: 'e1',
      type: AnalysisType.message,
      reliability: ReliabilityLevel.high,
      riskLevel: RiskLevel.dangerous,
      summary: '위험한 문자로 보여요.',
      createdAt: DateTime(2026, 1, 1),
    );
    repository.result = Ok(analysisResult);

    final result = await useCase(message);

    expect((result as Ok<AnalysisResult>).value, analysisResult);
  });
}
