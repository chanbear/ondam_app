import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/entities/sms_message.dart';
import '../../domain/repositories/message_risk_repository.dart';

/// No datasource file exists here on purpose — same reasoning as
/// `document_scan`'s `AnalysisRepositoryImpl`: there is no real risk-analysis
/// backend (Edge Function) yet, so this always returns
/// `Err(UnavailableFailure())`, never a fabricated [AnalysisResult]. When
/// that backend is built, add a datasource here and change this method to
/// call it — the [MessageRiskRepository] contract does not need to change.
class MessageRiskRepositoryImpl implements MessageRiskRepository {
  const MessageRiskRepositoryImpl();

  @override
  Future<Result<AnalysisResult>> analyzeMessage(SmsMessage message) async {
    return const Err(UnavailableFailure('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'));
  }
}
