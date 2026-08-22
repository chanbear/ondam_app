import 'package:ondam_models/ondam_models.dart';

/// DTO for a raw `analysis_results` row. `fromJson`/`toEntity()` written by
/// hand — `freezed`/`json_serializable` are not installed yet (api.md).
/// Mirrors Guardian's own `analysis` feature DTO of the same name exactly
/// (same table, same snake_case Postgrest row shape) — kept as a separate
/// file per app rather than shared, same rationale as
/// `document_scan`/`message_check`'s own copies of this DTO: same entity,
/// decoupled wire-parsing per data source.
///
/// Does NOT parse `action_items`/`important_dates`/`clarifying_questions` —
/// no such columns exist on this table (ONDAM 2.0 Phase 5's Edge Function
/// response fields are session-only, never persisted; see
/// `AnalysisResult`'s own field doc comments). A record fetched here always
/// has those three as null, which is the correct, honest outcome — not a
/// parsing gap.
class AnalysisResultModel {
  const AnalysisResultModel({
    required this.id,
    required this.elderId,
    required this.type,
    required this.reliability,
    required this.summary,
    required this.createdAt,
    this.riskLevel,
    this.sourceExcerpt,
    this.structuredFields,
    this.confirmedAt,
    this.billingAmountKrw,
    this.billingDate,
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    final confirmedAtRaw = json['confirmed_at'] as String?;
    final billingDateRaw = json['billing_date'] as String?;
    return AnalysisResultModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      type: json['type'] as String,
      reliability: json['reliability'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      riskLevel: json['risk_level'] as String?,
      sourceExcerpt: json['source_excerpt'] as String?,
      structuredFields: (json['structured_fields'] as Map?)
          ?.cast<String, Object?>(),
      confirmedAt: confirmedAtRaw != null
          ? DateTime.parse(confirmedAtRaw)
          : null,
      billingAmountKrw: json['billing_amount_krw'] as int?,
      billingDate: billingDateRaw != null
          ? DateTime.parse(billingDateRaw)
          : null,
    );
  }

  final String id;
  final String elderId;
  final String type;
  final String reliability;
  final String summary;
  final DateTime createdAt;
  final String? riskLevel;
  final String? sourceExcerpt;
  final Map<String, Object?>? structuredFields;
  final DateTime? confirmedAt;
  final int? billingAmountKrw;
  final DateTime? billingDate;

  AnalysisResult toEntity() {
    return AnalysisResult(
      id: id,
      elderId: elderId,
      type: AnalysisType.fromDbValue(type),
      reliability: ReliabilityLevel.fromDbValue(reliability),
      summary: summary,
      createdAt: createdAt,
      riskLevel: riskLevel != null ? RiskLevel.fromDbValue(riskLevel!) : null,
      sourceExcerpt: sourceExcerpt,
      structuredFields: structuredFields,
      confirmedAt: confirmedAt,
      billingAmountKrw: billingAmountKrw,
      billingDate: billingDate,
    );
  }
}
