import 'package:ondam_models/ondam_models.dart';

/// DTO for an `analysis_results` row. `fromJson`/`toEntity()` written by
/// hand — `freezed`/`json_serializable` are not installed yet (api.md).
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
    this.billingAmountKrw,
    this.billingDate,
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return AnalysisResultModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      type: json['type'] as String,
      reliability: json['reliability'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      riskLevel: json['risk_level'] as String?,
      sourceExcerpt: json['source_excerpt'] as String?,
      structuredFields: json['structured_fields'] as Map<String, Object?>?,
      billingAmountKrw: json['billing_amount_krw'] as int?,
      billingDate: json['billing_date'] != null
          ? DateTime.parse(json['billing_date'] as String)
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
      billingAmountKrw: billingAmountKrw,
      billingDate: billingDate,
    );
  }
}
