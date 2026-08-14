import 'package:ondam_models/ondam_models.dart';

/// DTO for `analyze-message`'s success response — a camelCase JSON body
/// (Edge Function response convention in this project, e.g.
/// `create-connection-token` returning `expiresAt` for the DB's
/// `expires_at`), NOT a raw `analysis_results` row. This is why it's a
/// separate file from Guardian's `AnalysisResultModel` (which parses a raw
/// snake_case Postgrest row read directly from the table) rather than a
/// shared one — same entity, different wire shape, same as api.md's
/// "Model → Entity 변환은 Model 쪽에 `toEntity()`" rule but per data source.
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
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return AnalysisResultModel(
      id: json['id'] as String,
      elderId: json['elderId'] as String,
      type: json['type'] as String,
      reliability: json['reliability'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      riskLevel: json['riskLevel'] as String?,
      sourceExcerpt: json['sourceExcerpt'] as String?,
      structuredFields: (json['structuredFields'] as Map?)
          ?.cast<String, Object?>(),
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
    );
  }
}
