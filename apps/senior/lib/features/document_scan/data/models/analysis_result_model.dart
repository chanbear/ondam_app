import 'package:ondam_models/ondam_models.dart';

/// DTO for `analyze-document`'s success response — camelCase JSON body
/// (same Edge Function response convention as `message_check`'s own copy of
/// this DTO). Kept as a separate file per feature rather than shared, same
/// rationale as `message_check/data/models/analysis_result_model.dart`'s doc
/// comment: same entity, decoupled wire-parsing per data source.
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
