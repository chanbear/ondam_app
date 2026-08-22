import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_result_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/providers/document_scan_di_providers.dart';
import 'package:ondam_senior/features/voice_assistant/presentation/pages/voice_assistant_page.dart';

import '../../domain/fakes/fake_analysis_repository.dart';

void main() {
  // Phase 8+: AnalysisRepositoryImpl now calls the real `analyze-document`
  // Edge Function (Supabase), so it can no longer be exercised end-to-end in
  // a widget test without a live backend — override with
  // FakeAnalysisRepository instead (default: Err(UnavailableFailure()),
  // same outcome this test always asserted). Same pattern as
  // message_risk_result_page_test.dart.
  testWidgets(
    'shows the Unavailable empty state (not a generic error, not a fake result) when there is no analysis backend',
    (tester) async {
      final photo = CapturedPhoto(
        localPath: '/tmp/photo.jpg',
        capturedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisRepositoryProvider.overrideWithValue(
              FakeAnalysisRepository()
                ..result = const Err(
                  UnavailableFailure('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'),
                ),
            ),
          ],
          child: MaterialApp(home: DocumentScanResultPage(photos: [photo])),
        ),
      );

      // Loading first — ONDAM 2.0 요구사항 12: 단계 기반 진행률 표시로
      // 대체됨(AnalysisProgressIndicator). 첫 단계는 "분석을 준비하고
      // 있어요".
      expect(find.text('분석을 준비하고 있어요'), findsOneWidget);

      await tester.pumpAndSettle();

      // Then the honest "not ready" state — never a fabricated result.
      expect(find.text('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    },
  );

  testWidgets(
    'Phase 6: 결과 화면의 "음성으로 물어보기" 버튼을 누르면 기존 VoiceAssistantPage로 이동한다',
    (tester) async {
      final photo = CapturedPhoto(
        localPath: '/tmp/photo.jpg',
        capturedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisRepositoryProvider.overrideWithValue(
              FakeAnalysisRepository()
                ..result = Ok(
                  AnalysisResult(
                    id: 'a1',
                    elderId: 'e1',
                    type: AnalysisType.document,
                    reliability: ReliabilityLevel.high,
                    summary: '전기요금 고지서예요.',
                    createdAt: DateTime(2026, 1, 1),
                    clarifyingQuestions: const ['이 고지서가 본인 명의가 맞나요?'],
                  ),
                ),
            ),
          ],
          child: MaterialApp(home: DocumentScanResultPage(photos: [photo])),
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

  group('ONDAM 2.0 요구사항 11 — 다중 문서 순차 분석', () {
    testWidgets('사진 2장을 순서대로 분석해 각각의 결과를 카드 목록으로 보여준다', (tester) async {
      final photo1 = CapturedPhoto(
        localPath: '/tmp/photo1.jpg',
        capturedAt: DateTime(2026, 1, 1),
      );
      final photo2 = CapturedPhoto(
        localPath: '/tmp/photo2.jpg',
        capturedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisRepositoryProvider.overrideWithValue(
              FakeAnalysisRepository()
                ..resultsQueue = [
                  Ok(
                    AnalysisResult(
                      id: 'a1',
                      elderId: 'e1',
                      type: AnalysisType.document,
                      reliability: ReliabilityLevel.high,
                      summary: '첫 번째 문서 요약',
                      createdAt: DateTime(2026, 1, 1),
                    ),
                  ),
                  Ok(
                    AnalysisResult(
                      id: 'a2',
                      elderId: 'e1',
                      type: AnalysisType.document,
                      reliability: ReliabilityLevel.medium,
                      summary: '두 번째 문서 요약',
                      createdAt: DateTime(2026, 1, 1),
                    ),
                  ),
                ],
            ),
          ],
          child: MaterialApp(
            home: DocumentScanResultPage(photos: [photo1, photo2]),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('문서 2건을 분석했어요'), findsOneWidget);
      expect(find.textContaining('첫 번째 문서 요약'), findsOneWidget);
      expect(find.textContaining('두 번째 문서 요약'), findsOneWidget);
    });

    testWidgets('첫 번째 사진 분석이 실패하면 두 번째는 요청하지 않고 오류를 보여준다', (tester) async {
      final photo1 = CapturedPhoto(
        localPath: '/tmp/photo1.jpg',
        capturedAt: DateTime(2026, 1, 1),
      );
      final photo2 = CapturedPhoto(
        localPath: '/tmp/photo2.jpg',
        capturedAt: DateTime(2026, 1, 1),
      );
      final fakeRepository = FakeAnalysisRepository()
        ..resultsQueue = [const Err(ServerFailure('서버 오류'))];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: MaterialApp(
            home: DocumentScanResultPage(photos: [photo1, photo2]),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('서버 오류'), findsOneWidget);
      expect(
        fakeRepository.calls,
        hasLength(1),
        reason: '첫 사진이 실패하면 나머지 사진은 분석 요청을 보내지 않아야 한다',
      );
    });
  });
}
