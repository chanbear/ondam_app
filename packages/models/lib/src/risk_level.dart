/// How dangerous a piece of content (a message, a document) appears to be.
/// Distinct from [ReliabilityLevel], which describes how confident the AI is
/// in its own analysis — not how risky the analyzed content is.
enum RiskLevel {
  safe,
  caution,
  dangerous;

  /// Matches the `risk_level` text column's
  /// `check (risk_level in ('safe', 'caution', 'dangerous'))` constraint in
  /// `supabase/migrations/20260814000001_create_analysis_results.sql`.
  String toDbValue() => name;

  static RiskLevel fromDbValue(String value) => switch (value) {
    'safe' => RiskLevel.safe,
    'caution' => RiskLevel.caution,
    'dangerous' => RiskLevel.dangerous,
    _ => throw ArgumentError('Unknown analysis_results.risk_level: $value'),
  };
}
