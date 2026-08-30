import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _emptyMessage = '아직 요금 통계가 없습니다.';

String _summaryBuilder(String pointsSummary) => '요금 추이 그래프. $pointsSummary';

void main() {
  testWidgets('데이터가 하나도 없으면 Empty State 문구를 보여준다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppFeeTrendChart(
          points: [
            FeeChartPoint(label: '1월', amountKrw: null),
            FeeChartPoint(label: '2월', amountKrw: null),
          ],
          emptyMessage: _emptyMessage,
          semanticNoDataLabel: _emptyMessage,
          semanticSummaryBuilder: _summaryBuilder,
        ),
      ),
    );

    expect(find.text('아직 요금 통계가 없습니다.'), findsOneWidget);
  });

  testWidgets('데이터가 1건뿐이어도 예외 없이 그려진다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppFeeTrendChart(
          points: [FeeChartPoint(label: '8월', amountKrw: 30000)],
          emptyMessage: _emptyMessage,
          semanticNoDataLabel: _emptyMessage,
          semanticSummaryBuilder: _summaryBuilder,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('아직 요금 통계가 없습니다.'), findsNothing);
  });

  testWidgets('일부 월에만 데이터가 있어도 시간축 라벨은 전부 유지된다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppFeeTrendChart(
          points: [
            FeeChartPoint(label: '1월', amountKrw: 10000),
            FeeChartPoint(label: '2월', amountKrw: null),
            FeeChartPoint(label: '3월', amountKrw: 20000),
          ],
          emptyMessage: _emptyMessage,
          semanticNoDataLabel: _emptyMessage,
          semanticSummaryBuilder: _summaryBuilder,
        ),
      ),
    );

    expect(find.text('1월'), findsOneWidget);
    expect(find.text('2월'), findsOneWidget);
    expect(find.text('3월'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('매우 큰 금액도 overflow 없이 렌더링된다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 200,
          child: AppFeeTrendChart(
            points: [
              FeeChartPoint(label: '1월', amountKrw: 999999999),
              FeeChartPoint(label: '2월', amountKrw: 1),
            ],
            emptyMessage: _emptyMessage,
            semanticNoDataLabel: _emptyMessage,
            semanticSummaryBuilder: _summaryBuilder,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('그래프 전체가 접근성 요약 문장을 갖는다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppFeeTrendChart(
          points: [FeeChartPoint(label: '8월', amountKrw: 30000)],
          emptyMessage: _emptyMessage,
          semanticNoDataLabel: _emptyMessage,
          semanticSummaryBuilder: _summaryBuilder,
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(AppFeeTrendChart));
    expect(semantics.label, contains('요금 추이 그래프'));
    expect(semantics.label, contains('30,000원'));
  });
}
