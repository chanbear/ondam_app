import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/sms_message.dart';

/// Submits a message (Android inbox selection or manual iOS/Android input)
/// for AI risk analysis via the `analyze-message` Edge Function (Phase 8,
/// real Anthropic backend — no longer the `UnavailableFailure`-only stub
/// this comment used to describe). This interface is kept separate from
/// `AnalysisRepository` only because the input type differs (`SmsMessage`
/// vs `CapturedPhoto`) — the output contract and Failure handling are
/// identical.
abstract class MessageRiskRepository {
  Future<Result<AnalysisResult>> analyzeMessage(
    SmsMessage message,
    String languageCode,
  );

  /// Notifies one linked guardian (via the `send-notification` Edge
  /// Function) that a risky message result was confirmed — 사용자가
  /// "보호자 알림"(notification_prefs)을 켜뒀을 때만 호출부(`MessageRiskNotifier`)가
  /// 이 메서드를 부른다. `targetUserId`는 accepted 상태인 `guardian_links`의
  /// `guardian_id`여야 한다(Edge Function이 그 관계를 서버에서 다시 검증).
  Future<Result<void>> notifyGuardian({
    required String targetUserId,
    required String analysisResultId,
  });
}
