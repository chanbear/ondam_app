import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/sms_message.dart';
import '../repositories/message_risk_repository.dart';

class CheckMessageRiskUseCase {
  const CheckMessageRiskUseCase(this._repository);

  final MessageRiskRepository _repository;

  Future<Result<AnalysisResult>> call(SmsMessage message) =>
      _repository.analyzeMessage(message);
}
