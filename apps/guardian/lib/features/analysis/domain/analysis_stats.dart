import 'package:ondam_models/ondam_models.dart';

/// Pure aggregation over already-fetched [AnalysisResult]s — kept out of
/// widget `build()` (riverpod.md). Only counts, never a fabricated billing
/// aggregate — `technical-decisions.md` OPEN QUESTIONS #12 (고지서 통계
/// 최종 데이터 항목) is still undecided, so this class deliberately does
/// NOT attempt to summarize `structuredFields` — the statistics tab renders
/// those generically per-record instead (see `StatisticsTabPage`).
class AnalysisStats {
  const AnalysisStats({
    required this.thisMonthCount,
    required this.lastMonthCount,
    required this.riskyThisMonthCount,
  });

  final int thisMonthCount;
  final int lastMonthCount;
  final int riskyThisMonthCount;

  /// Positive = grew vs last month, negative = shrank, zero = unchanged.
  /// The plain-language sentence built from this is a presentation-layer
  /// concern (needs `AppLocalizations`, which this domain class must not
  /// depend on) — see `StatisticsTabPage._trendSentence`.
  int get trendDelta => thisMonthCount - lastMonthCount;

  static AnalysisStats compute(List<AnalysisResult> records, DateTime now) {
    final lastMonth = DateTime(now.year, now.month - 1);
    return AnalysisStats(
      thisMonthCount: _countInMonth(records, now.year, now.month),
      lastMonthCount: _countInMonth(records, lastMonth.year, lastMonth.month),
      riskyThisMonthCount: records
          .where(
            (r) =>
                r.createdAt.year == now.year &&
                r.createdAt.month == now.month &&
                r.type == AnalysisType.message &&
                (r.riskLevel == RiskLevel.caution ||
                    r.riskLevel == RiskLevel.dangerous),
          )
          .length,
    );
  }

  static int _countInMonth(List<AnalysisResult> records, int year, int month) {
    return records
        .where((r) => r.createdAt.year == year && r.createdAt.month == month)
        .length;
  }
}
