/// One row of the `notifications` table (technical-decisions.md §4) —
/// generic across `type`, matching this codebase's precedent of not
/// hardcoding a value set the backend hasn't finalized yet (see
/// `AnalysisResult.structuredFields`). `payload` carries whatever the
/// sending Edge Function put there; for risk alerts this is expected to
/// include `elder_id`/`analysis_result_id` so the Guardian app can deep-link
/// into `AnalysisRecordDetailPage`, but that contract is not enforced here.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.targetUserId,
    required this.type,
    required this.payload,
    required this.sentVia,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String targetUserId;
  final String type;
  final Map<String, dynamic> payload;
  final String sentVia;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  /// Present only when the payload follows the risk-alert deep-link
  /// contract described above.
  String? get elderId => payload['elder_id'] as String?;

  /// Present only when the payload follows the risk-alert deep-link
  /// contract described above.
  String? get analysisResultId => payload['analysis_result_id'] as String?;
}
