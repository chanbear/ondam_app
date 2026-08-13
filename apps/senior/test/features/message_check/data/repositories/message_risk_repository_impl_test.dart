import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/message_check/data/repositories/message_risk_repository_impl.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';

void main() {
  const repository = MessageRiskRepositoryImpl();

  test(
    'analyzeMessage always returns UnavailableFailure — no risk-analysis backend exists yet',
    () async {
      final message = SmsMessage(
        sender: '010-1234-5678',
        body: '안녕하세요',
        receivedAt: DateTime(2026, 1, 1),
      );

      final result = await repository.analyzeMessage(message);

      expect(result, isA<Err<AnalysisResult>>());
      expect(
        (result as Err<AnalysisResult>).failure,
        isA<UnavailableFailure>(),
      );
    },
  );
}
