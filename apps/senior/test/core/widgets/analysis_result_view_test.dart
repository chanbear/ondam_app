import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/core/widgets/analysis_result_view.dart';

void main() {
  Widget wrap(AnalysisResult result) {
    return MaterialApp(
      home: Scaffold(body: AnalysisResultView(result: result)),
    );
  }

  AnalysisResult buildResult({
    required ReliabilityLevel reliability,
    RiskLevel? riskLevel,
    Map<String, Object?>? structuredFields,
  }) {
    return AnalysisResult(
      id: 'a1',
      elderId: 'e1',
      type: AnalysisType.document,
      reliability: reliability,
      summary: '전기요금 고지서예요.',
      createdAt: DateTime(2026, 1, 1),
      riskLevel: riskLevel,
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

  testWidgets('medium reliability shows the "조금 더 확인" sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.medium)),
    );

    expect(find.text('조금 더 확인이 필요해요.'), findsOneWidget);
  });

  testWidgets('low reliability shows the "정확하지 않을 수 있어요" sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.low)),
    );

    expect(find.text('정확하지 않을 수 있어요.'), findsOneWidget);
  });

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

  testWidgets(
    'omits the risk badge when riskLevel is null (document-only result)',
    (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );

      expect(find.text('위험 감지'), findsNothing);
      expect(find.text('안전'), findsNothing);
      expect(find.text('주의'), findsNothing);
    },
  );

  testWidgets('renders every structuredFields entry as a labeled row', (
    tester,
  ) async {
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
  });

  testWidgets('shows no structured-field section when the map is empty/null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.high)),
    );

    expect(find.text('문서 정보'), findsNothing);
  });
}
