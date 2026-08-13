import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/presentation/pages/message_risk_result_page.dart';

void main() {
  // MessageRiskRepositoryImpl has zero platform dependency (no SMS package,
  // no Supabase) — this test exercises the real Provider -> UseCase ->
  // Repository chain end to end, not a fake (same approach as
  // document_scan_result_page_test.dart).
  testWidgets(
    'shows the Unavailable empty state (not a generic error, not a fake result) when there is no risk-analysis backend',
    (tester) async {
      final message = SmsMessage(
        sender: '010-1234-5678',
        body: '[Web발신] 계좌 정지 안내',
        receivedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MessageRiskResultPage(message: message)),
        ),
      );

      // Loading first.
      expect(find.text('문자 내용을 확인하고 있어요'), findsOneWidget);

      await tester.pumpAndSettle();

      // Then the honest "not ready" state — never a fabricated risk result.
      expect(find.text('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    },
  );
}
