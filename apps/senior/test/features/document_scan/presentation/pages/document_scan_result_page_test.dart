import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_result_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/providers/document_scan_di_providers.dart';

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
          child: MaterialApp(home: DocumentScanResultPage(photo: photo)),
        ),
      );

      // Loading first.
      expect(find.text('문서 내용을 확인하고 있어요'), findsOneWidget);

      await tester.pumpAndSettle();

      // Then the honest "not ready" state — never a fabricated result.
      expect(find.text('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    },
  );
}
