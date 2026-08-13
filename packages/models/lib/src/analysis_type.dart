/// Source of an [AnalysisResult] — which Senior-app feature produced it.
enum AnalysisType {
  document,
  message;

  /// Matches the `type` text column's `check (type in ('document', 'message'))`
  /// constraint in `supabase/migrations/20260814000001_create_analysis_results.sql`.
  String toDbValue() => name;

  static AnalysisType fromDbValue(String value) => switch (value) {
    'document' => AnalysisType.document,
    'message' => AnalysisType.message,
    _ => throw ArgumentError('Unknown analysis_results.type: $value'),
  };
}
