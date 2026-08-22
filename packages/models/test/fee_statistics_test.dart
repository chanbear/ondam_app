import 'package:ondam_models/ondam_models.dart';
import 'package:test/test.dart';

AnalysisResult _doc({
  required String id,
  required DateTime createdAt,
  int? billingAmountKrw,
  DateTime? billingDate,
}) {
  return AnalysisResult(
    id: id,
    elderId: 'elder-1',
    type: AnalysisType.document,
    reliability: ReliabilityLevel.high,
    summary: '요약',
    createdAt: createdAt,
    billingAmountKrw: billingAmountKrw,
    billingDate: billingDate,
  );
}

AnalysisResult _message({
  required String id,
  required DateTime createdAt,
  int? billingAmountKrw,
}) {
  return AnalysisResult(
    id: id,
    elderId: 'elder-1',
    type: AnalysisType.message,
    reliability: ReliabilityLevel.high,
    summary: '요약',
    createdAt: createdAt,
    billingAmountKrw: billingAmountKrw,
  );
}

void main() {
  group('FeeStatisticsCalculator.extractPoints', () {
    test('billingAmountKrw가 null인 기록은 제외한다', () {
      final records = [
        _doc(id: 'a1', createdAt: DateTime(2026, 8, 1), billingAmountKrw: null),
        _doc(
          id: 'a2',
          createdAt: DateTime(2026, 8, 2),
          billingAmountKrw: 10000,
        ),
      ];

      final points = FeeStatisticsCalculator.extractPoints(records);

      expect(points, hasLength(1));
      expect(points.single.amountKrw, 10000);
    });

    test('document가 아닌(message) 기록은 제외한다', () {
      final records = [
        _message(
          id: 'm1',
          createdAt: DateTime(2026, 8, 1),
          billingAmountKrw: 5000,
        ),
      ];

      expect(FeeStatisticsCalculator.extractPoints(records), isEmpty);
    });

    test('billingDate가 있으면 그 날짜를, 없으면 createdAt을 기준 날짜로 쓴다', () {
      final records = [
        _doc(
          id: 'a1',
          createdAt: DateTime(2026, 8, 15),
          billingAmountKrw: 10000,
          billingDate: DateTime(2026, 7, 1),
        ),
        _doc(
          id: 'a2',
          createdAt: DateTime(2026, 8, 20),
          billingAmountKrw: 20000,
        ),
      ];

      final points = FeeStatisticsCalculator.extractPoints(records);

      expect(points[0].date, DateTime(2026, 7, 1));
      expect(points[1].date, DateTime(2026, 8, 20));
    });
  });

  group('FeeSummary', () {
    test('빈 목록은 FeeSummary.empty와 동일하다', () {
      expect(FeeSummary.of([]), FeeSummary.empty);
      expect(FeeSummary.empty.isEmpty, isTrue);
    });

    test('단일 데이터도 정상적으로 총/평균/최고/최저가 그 값 하나로 계산된다', () {
      final summary = FeeSummary.of([
        FeePoint(amountKrw: 30000, date: DateTime(2026, 8, 1)),
      ]);

      expect(summary.totalKrw, 30000);
      expect(summary.averageKrw, 30000);
      expect(summary.maxKrw, 30000);
      expect(summary.minKrw, 30000);
      expect(summary.count, 1);
    });

    test('여러 값의 총/평균/최고/최저/건수를 정확히 계산한다', () {
      final summary = FeeSummary.of([
        FeePoint(amountKrw: 10000, date: DateTime(2026, 1, 1)),
        FeePoint(amountKrw: 30000, date: DateTime(2026, 2, 1)),
        FeePoint(amountKrw: 20000, date: DateTime(2026, 3, 1)),
      ]);

      expect(summary.totalKrw, 60000);
      expect(summary.averageKrw, 20000);
      expect(summary.maxKrw, 30000);
      expect(summary.minKrw, 10000);
      expect(summary.count, 3);
    });
  });

  group('FeeStatisticsCalculator.monthly', () {
    test('데이터가 하나도 없으면 각 달이 hasData: false인 채로 시간축은 유지된다', () {
      final result = FeeStatisticsCalculator.monthly(
        [],
        end: DateTime(2026, 3, 1),
        months: 3,
      );

      expect(result, hasLength(3));
      expect(result.map((m) => (m.year, m.month)), [
        (2026, 1),
        (2026, 2),
        (2026, 3),
      ]);
      expect(result.every((m) => !m.hasData), isTrue);
    });

    test('여러 달에 걸친 데이터를 각 달로 정확히 집계한다', () {
      final records = [
        _doc(
          id: 'a1',
          createdAt: DateTime(2026, 1, 10),
          billingAmountKrw: 10000,
        ),
        _doc(
          id: 'a2',
          createdAt: DateTime(2026, 1, 20),
          billingAmountKrw: 20000,
        ),
        _doc(id: 'a3', createdAt: DateTime(2026, 2, 5), billingAmountKrw: 5000),
      ];

      final result = FeeStatisticsCalculator.monthly(
        records,
        end: DateTime(2026, 2, 28),
        months: 2,
      );

      expect(result[0].year, 2026);
      expect(result[0].month, 1);
      expect(result[0].summary.totalKrw, 30000);
      expect(result[0].summary.count, 2);

      expect(result[1].month, 2);
      expect(result[1].summary.totalKrw, 5000);
      expect(result[1].summary.count, 1);
    });

    test('연도 경계를 넘어가는 개월 수도 올바르게 계산한다', () {
      final records = [
        _doc(
          id: 'a1',
          createdAt: DateTime(2025, 12, 15),
          billingAmountKrw: 7000,
        ),
      ];

      final result = FeeStatisticsCalculator.monthly(
        records,
        end: DateTime(2026, 1, 31),
        months: 2,
      );

      expect(result[0].year, 2025);
      expect(result[0].month, 12);
      expect(result[0].summary.totalKrw, 7000);
      expect(result[1].year, 2026);
      expect(result[1].month, 1);
      expect(result[1].hasData, isFalse);
    });
  });

  group('FeeStatisticsCalculator.yearly', () {
    test('여러 연도에 걸친 데이터를 각 연도로 정확히 집계한다', () {
      final records = [
        _doc(
          id: 'a1',
          createdAt: DateTime(2024, 6, 1),
          billingAmountKrw: 10000,
        ),
        _doc(
          id: 'a2',
          createdAt: DateTime(2025, 6, 1),
          billingAmountKrw: 20000,
        ),
        _doc(
          id: 'a3',
          createdAt: DateTime(2025, 7, 1),
          billingAmountKrw: 40000,
        ),
        _doc(id: 'a4', createdAt: DateTime(2026, 1, 1), billingAmountKrw: 5000),
      ];

      final result = FeeStatisticsCalculator.yearly(
        records,
        end: DateTime(2026, 8, 20),
        startYear: 2024,
      );

      expect(result.map((y) => y.year), [2024, 2025, 2026]);
      expect(result[0].summary.totalKrw, 10000);
      expect(result[1].summary.totalKrw, 60000);
      expect(result[1].summary.count, 2);
      expect(result[2].summary.totalKrw, 5000);
    });

    test('데이터가 없는 연도는 hasData: false로 표시되지만 시간축에는 포함된다', () {
      final result = FeeStatisticsCalculator.yearly(
        [],
        end: DateTime(2026, 1, 1),
        startYear: 2024,
      );

      expect(result, hasLength(3));
      expect(result.every((y) => !y.hasData), isTrue);
    });
  });
}
