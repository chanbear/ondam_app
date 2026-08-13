/// User-facing confidence in an AI analysis result — "높음/보통/낮음" per
/// ui-spec.md. Never derived from or equal to a raw model confidence score;
/// the mapping from raw score to this enum happens in the Senior app's
/// `analysis` feature (domain layer), not here.
enum ReliabilityLevel {
  high,
  medium,
  low;

  /// Matches the `reliability` text column's
  /// `check (reliability in ('high', 'medium', 'low'))` constraint in
  /// `supabase/migrations/20260814000001_create_analysis_results.sql`.
  String toDbValue() => name;

  static ReliabilityLevel fromDbValue(String value) => switch (value) {
    'high' => ReliabilityLevel.high,
    'medium' => ReliabilityLevel.medium,
    'low' => ReliabilityLevel.low,
    _ => throw ArgumentError('Unknown analysis_results.reliability: $value'),
  };
}
