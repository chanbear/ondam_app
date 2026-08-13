import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/analysis/domain/analysis_stats.dart';
import 'package:ondam_models/ondam_models.dart';

AnalysisResult _record({
  required DateTime createdAt,
  AnalysisType type = AnalysisType.document,
  RiskLevel? riskLevel,
}) {
  return AnalysisResult(
    id: 'r-${createdAt.toIso8601String()}-$riskLevel',
    elderId: 'e1',
    type: type,
    reliability: ReliabilityLevel.high,
    summary: 's',
    createdAt: createdAt,
    riskLevel: riskLevel,
  );
}

void main() {
  final now = DateTime(2026, 8, 15);

  test('빈 목록이면 모든 집계가 0이다(고지서 데이터 없음)', () {
    final stats = AnalysisStats.compute(const [], now);

    expect(stats.thisMonthCount, 0);
    expect(stats.lastMonthCount, 0);
    expect(stats.riskyThisMonthCount, 0);
    expect(stats.trendSentence, '지난달과 동일해요');
  });

  test('이번 달 기록만 이번 달 건수에 포함한다', () {
    final records = [
      _record(createdAt: DateTime(2026, 8, 1)),
      _record(createdAt: DateTime(2026, 7, 30)),
    ];
    final stats = AnalysisStats.compute(records, now);

    expect(stats.thisMonthCount, 1);
    expect(stats.lastMonthCount, 1);
  });

  test('지난달보다 늘었으면 늘어난 건수를 문장으로 보여준다', () {
    final records = [
      _record(createdAt: DateTime(2026, 8, 1)),
      _record(createdAt: DateTime(2026, 8, 2)),
      _record(createdAt: DateTime(2026, 7, 1)),
    ];
    final stats = AnalysisStats.compute(records, now);

    expect(stats.trendDelta, 1);
    expect(stats.trendSentence, '지난달보다 1건 늘었어요');
  });

  test('지난달보다 줄었으면 줄어든 건수를 문장으로 보여준다', () {
    final records = [
      _record(createdAt: DateTime(2026, 8, 1)),
      _record(createdAt: DateTime(2026, 7, 1)),
      _record(createdAt: DateTime(2026, 7, 2)),
    ];
    final stats = AnalysisStats.compute(records, now);

    expect(stats.trendDelta, -1);
    expect(stats.trendSentence, '지난달보다 1건 줄었어요');
  });

  test('위험 문자 건수는 이번 달 message 타입 중 caution/dangerous만 센다', () {
    final records = [
      _record(
        createdAt: DateTime(2026, 8, 1),
        type: AnalysisType.message,
        riskLevel: RiskLevel.dangerous,
      ),
      _record(
        createdAt: DateTime(2026, 8, 2),
        type: AnalysisType.message,
        riskLevel: RiskLevel.safe,
      ),
      _record(createdAt: DateTime(2026, 8, 3), type: AnalysisType.document),
      _record(
        createdAt: DateTime(2026, 7, 1),
        type: AnalysisType.message,
        riskLevel: RiskLevel.caution,
      ),
    ];
    final stats = AnalysisStats.compute(records, now);

    expect(stats.riskyThisMonthCount, 1);
  });
}
