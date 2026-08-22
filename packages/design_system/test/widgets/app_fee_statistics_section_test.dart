import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

// 실제 호출부(Senior FeeStatisticsPage의 AppScaffold(scrollable: true),
// Guardian StatisticsTabPage의 ListView)는 항상 이 섹션을 스크롤 가능한
// 컨테이너 안에서 사용한다 — 이 위젯 자체는 스크롤을 책임지지 않는다(파일
// 상단 doc comment 참고). 스크롤 없는 고정 높이 컨테이너로 감싸면 선택
// 상세 카드가 추가될 때 테스트 환경에서만 인위적으로 overflow가 발생한다.
Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

AnalysisResult _doc({
  required String id,
  required DateTime createdAt,
  int? billingAmountKrw,
}) {
  return AnalysisResult(
    id: id,
    elderId: 'e1',
    type: AnalysisType.document,
    reliability: ReliabilityLevel.high,
    summary: '요약',
    createdAt: createdAt,
    billingAmountKrw: billingAmountKrw,
  );
}

void main() {
  testWidgets('요금 기록이 하나도 없으면 Empty State를 보여준다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppFeeStatisticsSection(
          records: [_doc(id: 'a1', createdAt: DateTime(2026, 8, 1))],
        ),
      ),
    );

    expect(
      find.text('아직 요금 통계가 없습니다.\n고지서나 요금서를 분석하면 통계가 만들어집니다.'),
      findsOneWidget,
    );
  });

  testWidgets('요금 기록이 있으면 총/평균/최고/건수 카드를 보여준다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppFeeStatisticsSection(
          records: [
            _doc(
              id: 'a1',
              createdAt: DateTime(2026, 8, 1),
              billingAmountKrw: 10000,
            ),
            _doc(
              id: 'a2',
              createdAt: DateTime(2026, 8, 15),
              billingAmountKrw: 30000,
            ),
          ],
        ),
      ),
    );

    expect(find.text('총 요금'), findsOneWidget);
    expect(find.text('40,000원'), findsOneWidget);
    expect(find.text('평균 요금'), findsOneWidget);
    expect(find.text('20,000원'), findsOneWidget);
    expect(find.text('최고 요금'), findsOneWidget);
    expect(find.text('30,000원'), findsOneWidget);
    expect(find.text('요금 내역'), findsOneWidget);
    expect(find.text('2건'), findsOneWidget);
  });

  testWidgets('기본값은 월별 보기이며, 연별 버튼을 누르면 연별 추이로 전환된다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppFeeStatisticsSection(
          records: [
            _doc(
              id: 'a1',
              createdAt: DateTime(2025, 8, 1),
              billingAmountKrw: 10000,
            ),
          ],
        ),
      ),
    );

    expect(find.text('월별 요금 추이'), findsOneWidget);

    await tester.tap(find.text('연별'));
    await tester.pumpAndSettle();

    expect(find.text('연별 요금 추이'), findsOneWidget);
  });

  testWidgets('그래프 지점을 선택하면 해당 기간의 상세 카드가 나타난다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppFeeStatisticsSection(
          records: [
            _doc(
              id: 'a1',
              createdAt: DateTime(2026, 8, 1),
              billingAmountKrw: 10000,
            ),
          ],
        ),
      ),
    );

    final chart = tester.widget<AppFeeTrendChart>(
      find.byType(AppFeeTrendChart),
    );
    chart.onSelect!(chart.points.indexWhere((p) => p.hasData));
    await tester.pumpAndSettle();

    expect(find.text('건수'), findsOneWidget);
  });

  testWidgets('월별/연별 전환 버튼은 최소 44x44 논리 픽셀 터치 영역을 확보한다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppFeeStatisticsSection(
          records: [
            _doc(
              id: 'a1',
              createdAt: DateTime(2026, 8, 1),
              billingAmountKrw: 10000,
            ),
          ],
        ),
      ),
    );

    final monthlySize = tester.getSize(
      find.ancestor(of: find.text('월별'), matching: find.byType(InkWell)),
    );
    final yearlySize = tester.getSize(
      find.ancestor(of: find.text('연별'), matching: find.byType(InkWell)),
    );

    expect(monthlySize.height, greaterThanOrEqualTo(44));
    expect(yearlySize.height, greaterThanOrEqualTo(44));
  });
}
