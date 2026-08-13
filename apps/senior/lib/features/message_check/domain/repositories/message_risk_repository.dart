import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/sms_message.dart';

/// Submits a message (Android inbox selection or manual iOS/Android input)
/// for AI risk analysis. As of this Phase, no risk-analysis backend exists
/// (no Edge Function) — the implementation returns
/// `Err(UnavailableFailure())` deliberately, never a fabricated
/// [AnalysisResult] (same rule `document_scan`'s `AnalysisRepository`
/// follows for photos). Both `document_scan` and `message_check` will call
/// into the same real backend once it exists; this interface is kept
/// separate from `AnalysisRepository` only because the input type differs
/// (`SmsMessage` vs `CapturedPhoto`) — the output contract and Failure
/// handling are identical.
abstract class MessageRiskRepository {
  Future<Result<AnalysisResult>> analyzeMessage(SmsMessage message);
}
