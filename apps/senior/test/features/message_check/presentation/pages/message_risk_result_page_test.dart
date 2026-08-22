import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/presentation/pages/message_risk_result_page.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/message_check_di_providers.dart';
import 'package:ondam_senior/features/voice_assistant/presentation/pages/voice_assistant_page.dart';

import '../../domain/fakes/fake_message_risk_repository.dart';

void main() {
  // Phase 8: MessageRiskRepositoryImpl now calls the real `analyze-message`
  // Edge Function (Supabase), so it can no longer be exercised end-to-end in
  // a widget test without a live backend — override with
  // FakeMessageRiskRepository instead (default: Err(UnavailableFailure()),
  // same outcome this test always asserted). The assertion below is
  // unchanged: a real backend returning "not configured" (no AI provider
  // secret in this environment) must still render as the honest Unavailable
  // empty state, never a fabricated risk result.
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
          overrides: [
            messageRiskRepositoryProvider.overrideWithValue(
              FakeMessageRiskRepository()
                ..result = const Err(
                  UnavailableFailure('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'),
                ),
            ),
          ],
          child: MaterialApp(home: MessageRiskResultPage(message: message)),
        ),
      );

      // Loading first — ONDAM 2.0 요구사항 21: 단계 기반 진행률 표시로
      // 대체됨(AnalysisProgressIndicator). 첫 단계는 "분석을 준비하고
      // 있어요".
      expect(find.text('분석을 준비하고 있어요'), findsOneWidget);

      await tester.pumpAndSettle();

      // Then the honest "not ready" state — never a fabricated risk result.
      expect(find.text('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    },
  );

  testWidgets(
    'Phase 6: 결과 화면의 "음성으로 물어보기" 버튼을 누르면 기존 VoiceAssistantPage로 이동한다',
    (tester) async {
      final message = SmsMessage(
        sender: '010-1234-5678',
        body: '[Web발신] 계좌 정지 안내',
        receivedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            messageRiskRepositoryProvider.overrideWithValue(
              FakeMessageRiskRepository()
                ..result = Ok(
                  AnalysisResult(
                    id: 'a1',
                    elderId: 'e1',
                    type: AnalysisType.message,
                    reliability: ReliabilityLevel.medium,
                    summary: '일반적인 안내 문자예요.',
                    createdAt: DateTime(2026, 1, 1),
                    riskLevel: RiskLevel.safe,
                  ),
                ),
            ),
          ],
          child: MaterialApp(home: MessageRiskResultPage(message: message)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('음성으로 물어보기'), findsOneWidget);

      await tester.tap(find.text('음성으로 물어보기'));
      // MaterialPageRoute push는 한 프레임 안에 완전히 반영되지 않는다 —
      // pumpAndSettle()은 VoiceAssistantPage 내부의 micPermissionProvider가
      // 이 테스트 환경(플랫폼 채널 mock 없음)에서 계속 재빌드를 유발하면
      // 끝나지 않을 수 있어, 대신 프레임을 여러 번 넘겨 push가 반영될
      // 시간만 준다.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VoiceAssistantPage), findsOneWidget);
    },
  );
}
