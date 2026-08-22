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
    this.actionItems,
    this.importantDates,
    this.clarifyingQuestions,
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
      actionItems: _parseActionItems(json['actionItems']),
      importantDates: _parseImportantDates(json['importantDates']),
      clarifyingQuestions: (json['clarifyingQuestions'] as List?)
          ?.cast<String>(),
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

  // ONDAM 2.0 Phase 5부터 analyze-document가 실제로 채워 보낸다. DB
  // 컬럼이 없어 이 응답에만 실려 오고 재조회 시에는 사라지므로(index.ts
  // 주석 참고) 여전히 null일 수 있다 — 기존 응답(이 키들이 아예 없는
  // 경우)도 그대로 동작해야 한다(하위 호환).
  final List<ActionItem>? actionItems;
  final List<ImportantDate>? importantDates;
  final List<String>? clarifyingQuestions;

  static List<ActionItem>? _parseActionItems(Object? raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map(
          (e) => ActionItem(
            id: e['id'] as String,
            title: e['title'] as String,
            completed: e['completed'] as bool? ?? false,
          ),
        )
        .toList();
  }

  static List<ImportantDate>? _parseImportantDates(Object? raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map(
          (e) => ImportantDate(
            date: DateTime.parse(e['date'] as String),
            kind: ImportantDateKind.fromWireValue(e['kind'] as String),
            label: e['label'] as String?,
            priority: e['priority'] != null
                ? ImportantDatePriority.fromWireValue(e['priority'] as String)
                : ImportantDatePriority.medium,
            needsSourceEvidence: e['needsSourceEvidence'] as bool? ?? false,
          ),
        )
        .toList();
  }

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
      actionItems: actionItems,
      importantDates: importantDates,
      clarifyingQuestions: clarifyingQuestions,
    );
  }
}
