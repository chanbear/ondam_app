import 'analysis_type.dart';
import 'reliability_level.dart';
import 'risk_level.dart';

/// Shared shape for a document/message analysis result — produced by the
/// Senior app (`document_scan`, `message_check`) and read by the Guardian
/// app (`guardian`, billing statistics). Field list is a skeleton matching
/// the `analysis_results` table sketched in technical-decisions.md §4; it
/// will grow as those features are actually implemented.
class AnalysisResult {
  const AnalysisResult({
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

  final String id;
  final String elderId;
  final AnalysisType type;
  final ReliabilityLevel reliability;
  final String summary;
  final DateTime createdAt;

  /// Only meaningful for [AnalysisType.message] today; documents may gain
  /// risk scoring later.
  final RiskLevel? riskLevel;

  final String? sourceExcerpt;

  /// Bill/document structured fields (amount, due date, category, ...) used
  /// by the Guardian app's billing statistics. Shape intentionally open
  /// (`Map`) until feature-spec.md ADD/NEW-5 finalizes the concrete fields.
  final Map<String, Object?>? structuredFields;
}
