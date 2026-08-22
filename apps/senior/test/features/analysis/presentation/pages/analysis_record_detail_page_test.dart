import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/analysis/presentation/pages/analysis_record_detail_page.dart';
import 'package:ondam_senior/features/voice_assistant/presentation/pages/voice_assistant_page.dart';

void main() {
  AnalysisResult buildResult() {
    return AnalysisResult(
      id: 'a1',
      elderId: 'e1',
      type: AnalysisType.document,
      reliability: ReliabilityLevel.high,
      summary: '전기요금 고지서예요.',
      createdAt: DateTime(2026, 8, 1),
      riskLevel: RiskLevel.safe,
    );
  }

  Widget wrap(AnalysisResult result) {
    return ProviderScope(
      child: MaterialApp(home: AnalysisRecordDetailPage(result: result)),
    );
  }

  testWidgets('기존 AnalysisResultView를 그대로 사용해 요약/위험도를 보여준다', (tester) async {
    await tester.pumpWidget(wrap(buildResult()));
    await tester.pumpAndSettle();

    // 문장 구분 부호가 없는 짧은 summary라 "주요 내용"과 "AI 요약" 두
    // 곳에서 동일한 문자열이 그대로 보인다(extractKeyPoint 폴백, ONDAM
    // 2.0 요구사항 14).
    expect(find.text('전기요금 고지서예요.'), findsWidgets);
    expect(find.text('안전'), findsOneWidget);
  });

  testWidgets('"음성으로 물어보기" 버튼을 누르면 기존 VoiceAssistantPage로 이동한다', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(buildResult()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('음성으로 물어보기'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(VoiceAssistantPage), findsOneWidget);
  });
}
