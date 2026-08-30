import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/domain/repositories/message_risk_repository.dart';

class FakeMessageRiskRepository implements MessageRiskRepository {
  Result<AnalysisResult> result = const Err(UnavailableFailure());
  Result<void> notifyGuardianResult = const Ok(null);

  final List<SmsMessage> calls = [];
  final List<String> notifyGuardianCalls = [];

  @override
  Future<Result<AnalysisResult>> analyzeMessage(SmsMessage message) async {
    calls.add(message);
    return result;
  }

  @override
  Future<Result<void>> notifyGuardian({
    required String targetUserId,
    required String analysisResultId,
  }) async {
    notifyGuardianCalls.add(targetUserId);
    return notifyGuardianResult;
  }
}
