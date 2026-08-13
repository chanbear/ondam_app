import 'package:ondam_models/ondam_models.dart';

/// Pure logic for "가장 심각한 위험도" — kept out of widget `build()` per
/// riverpod.md ("비즈니스 규칙... UseCase/Provider로 옮긴다"). Risk and
/// reliability are deliberately different axes (Phase 6 지시 5) — this
/// helper only ever looks at [AnalysisResult.riskLevel], never reliability.
abstract final class RiskSummary {
  /// Null if [records] is empty or none of them carry a risk level
  /// (document-type records have no risk level today).
  static RiskLevel? worst(List<AnalysisResult> records) {
    RiskLevel? worst;
    for (final record in records) {
      final risk = record.riskLevel;
      if (risk == null) continue;
      if (worst == null || _severity(risk) > _severity(worst)) {
        worst = risk;
      }
    }
    return worst;
  }

  static int _severity(RiskLevel level) => switch (level) {
    RiskLevel.safe => 0,
    RiskLevel.caution => 1,
    RiskLevel.dangerous => 2,
  };
}
