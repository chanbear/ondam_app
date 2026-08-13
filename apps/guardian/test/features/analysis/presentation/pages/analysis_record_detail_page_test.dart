import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/analysis/presentation/pages/analysis_record_detail_page.dart';
import 'package:ondam_models/ondam_models.dart';

void main() {
  Widget wrap(AnalysisResult result) {
    return MaterialApp(home: AnalysisRecordDetailPage(result: result));
  }

  AnalysisResult buildResult({
    required ReliabilityLevel reliability,
    RiskLevel? riskLevel,
    String? sourceExcerpt,
    Map<String, Object?>? structuredFields,
  }) {
    return AnalysisResult(
      id: 'a1',
      elderId: 'e1',
      type: AnalysisType.message,
      reliability: reliability,
      summary: '전기요금 고지서예요.',
      createdAt: DateTime(2026, 1, 1),
      riskLevel: riskLevel,
      sourceExcerpt: sourceExcerpt,
      structuredFields: structuredFields,
    );
  }

  testWidgets(
    'high reliability shows the plain-language sentence, never a number',
    (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );

      expect(find.text('이 답변은 비교적 확실해요.'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    },
  );

  testWidgets('renders a risk badge only when riskLevel is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        buildResult(
          reliability: ReliabilityLevel.high,
          riskLevel: RiskLevel.dangerous,
        ),
      ),
    );

    expect(find.text('위험 감지'), findsOneWidget);
  });

  testWidgets('omits the risk badge when riskLevel is null', (tester) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.high)),
    );

    expect(find.text('위험 감지'), findsNothing);
    expect(find.text('주의'), findsNothing);
  });

  testWidgets('shows the source excerpt only when present', (tester) async {
    await tester.pumpWidget(
      wrap(
        buildResult(
          reliability: ReliabilityLevel.high,
          sourceExcerpt: '[Web발신] 택배 배송 조회...',
        ),
      ),
    );

    expect(find.text('원문'), findsOneWidget);
    expect(find.text('[Web발신] 택배 배송 조회...'), findsOneWidget);
  });

  testWidgets('omits the 원문 section when sourceExcerpt is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.high)),
    );

    expect(find.text('원문'), findsNothing);
  });

  testWidgets(
    'renders every structuredFields entry generically as a labeled row',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            structuredFields: const {'금액': '32,000원', '납부기한': '2026-01-31'},
          ),
        ),
      );

      expect(find.text('금액'), findsOneWidget);
      expect(find.text('32,000원'), findsOneWidget);
      expect(find.text('납부기한'), findsOneWidget);
      expect(find.text('2026-01-31'), findsOneWidget);
    },
  );

  testWidgets('shows no structured-field section when the map is empty/null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.high)),
    );

    expect(find.text('구조화 정보'), findsNothing);
  });
}
