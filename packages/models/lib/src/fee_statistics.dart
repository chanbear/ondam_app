import 'analysis_result.dart';
import 'analysis_type.dart';

/// One 요금(fee) record contributing to statistics — always derived from an
/// [AnalysisResult] that has a real [AnalysisResult.billingAmountKrw] (PHASE
/// 37). Never fabricated: a record with a null amount never becomes one of
/// these.
class FeePoint {
  const FeePoint({required this.amountKrw, required this.date});

  final int amountKrw;

  /// 날짜 우선순위: `billingDate` → `createdAt` (AnalysisResult 필드 주석과
  /// 동일한 규칙) — 항상 non-null이다(`createdAt`이 DB NOT NULL이므로).
  final DateTime date;
}

/// Total/average/max/min/count over a set of [FeePoint]s — shared by
/// Senior(본인 통계)/Guardian(연결된 어르신 통계) so both apps read the same
/// numbers from the same records (PHASE 37 §6 "같은 데이터를 보았을 때 값이
/// 다르게 나오지 않도록"). Pure Dart, no Flutter/Riverpod dependency
/// (architecture.md: domain은 외부 패키지에 의존하지 않는다).
class FeeSummary {
  const FeeSummary({
    required this.totalKrw,
    required this.averageKrw,
    required this.maxKrw,
    required this.minKrw,
    required this.count,
  });

  final int totalKrw;
  final int averageKrw;
  final int maxKrw;
  final int minKrw;
  final int count;

  bool get isEmpty => count == 0;

  static const empty = FeeSummary(
    totalKrw: 0,
    averageKrw: 0,
    maxKrw: 0,
    minKrw: 0,
    count: 0,
  );

  static FeeSummary of(List<FeePoint> points) {
    if (points.isEmpty) return empty;
    final amounts = points.map((p) => p.amountKrw);
    final total = amounts.reduce((a, b) => a + b);
    return FeeSummary(
      totalKrw: total,
      averageKrw: total ~/ points.length,
      maxKrw: amounts.reduce((a, b) => a > b ? a : b),
      minKrw: amounts.reduce((a, b) => a < b ? a : b),
      count: points.length,
    );
  }
}

/// 특정 연-월의 요금 통계 한 칸 — 데이터가 없는 달도 [summary]가
/// [FeeSummary.empty]인 채로 시간축에 나타날 수 있게 [year]/[month]는 항상
/// 채워진다(PHASE 37 §2: "데이터가 없는 월은 0으로 억지 계산하지 말고
/// '데이터 없음' 상태를 적절히 처리... 그래프의 시간축 자체는 정상적으로
/// 유지").
class MonthlyFeeStatistics {
  const MonthlyFeeStatistics({
    required this.year,
    required this.month,
    required this.summary,
  });

  final int year;
  final int month;
  final FeeSummary summary;

  bool get hasData => !summary.isEmpty;
}

/// 특정 연도의 요금 통계 한 칸 — [MonthlyFeeStatistics]와 동일한 이유로
/// 데이터 없는 연도도 [year]는 채워진 채로 나타날 수 있다.
class YearlyFeeStatistics {
  const YearlyFeeStatistics({required this.year, required this.summary});

  final int year;
  final FeeSummary summary;

  bool get hasData => !summary.isEmpty;
}

/// [AnalysisResult] 목록으로부터 요금 통계를 계산하는 순수 함수 모음
/// (packages/models — Senior/Guardian 양쪽이 그대로 import해 중복 구현을
/// 피한다, PHASE 37 §6/§13). UI에 직접 계산 로직을 두지 않는다(riverpod.md).
class FeeStatisticsCalculator {
  const FeeStatisticsCalculator._();

  /// 통계 대상 필터링 — PHASE 37 §8 "다음 데이터는 통계에서 제외": 금액이
  /// null이거나(AI가 추출하지 못함) document 타입이 아닌 기록(message는
  /// billingAmountKrw가 항상 null이므로 자연히 제외되지만, 의도를 명시적으로
  /// 남긴다). 날짜는 billingDate가 없으면 createdAt으로 대체하므로 날짜
  /// 부재로 제외되는 기록은 없다(createdAt은 항상 존재).
  static List<FeePoint> extractPoints(List<AnalysisResult> records) {
    return records
        .where(
          (r) => r.type == AnalysisType.document && r.billingAmountKrw != null,
        )
        .map(
          (r) => FeePoint(
            amountKrw: r.billingAmountKrw!,
            date: r.billingDate ?? r.createdAt,
          ),
        )
        .toList();
  }

  static FeeSummary overall(List<AnalysisResult> records) {
    return FeeSummary.of(extractPoints(records));
  }

  /// [months]개월치를 최신 월부터 역순이 아니라 **오래된 달 → 최근 달** 순으로
  /// 반환한다 — 선 그래프 시간축과 그대로 대응시키기 위함. [end]가 속한 달을
  /// 마지막 칸으로 포함한다(기본값: 오늘).
  static List<MonthlyFeeStatistics> monthly(
    List<AnalysisResult> records, {
    required DateTime end,
    int months = 12,
  }) {
    final points = extractPoints(records);
    final result = <MonthlyFeeStatistics>[];
    for (var i = months - 1; i >= 0; i--) {
      final target = DateTime(end.year, end.month - i);
      final inMonth = points.where(
        (p) => p.date.year == target.year && p.date.month == target.month,
      );
      result.add(
        MonthlyFeeStatistics(
          year: target.year,
          month: target.month,
          summary: FeeSummary.of(inMonth.toList()),
        ),
      );
    }
    return result;
  }

  /// [startYear]부터 [end]가 속한 연도까지, **오래된 연도 → 최근 연도** 순.
  static List<YearlyFeeStatistics> yearly(
    List<AnalysisResult> records, {
    required DateTime end,
    required int startYear,
  }) {
    final points = extractPoints(records);
    final result = <YearlyFeeStatistics>[];
    for (var year = startYear; year <= end.year; year++) {
      final inYear = points.where((p) => p.date.year == year);
      result.add(
        YearlyFeeStatistics(
          year: year,
          summary: FeeSummary.of(inYear.toList()),
        ),
      );
    }
    return result;
  }
}
