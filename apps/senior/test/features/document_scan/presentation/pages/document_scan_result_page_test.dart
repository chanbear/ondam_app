import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_result_page.dart';

void main() {
  // AnalysisRepositoryImpl has zero platform dependency (no camera, no
  // permission_handler, no Supabase) — this test exercises the real
  // Provider -> UseCase -> Repository chain end to end, not a fake.
  testWidgets(
    'shows the Unavailable empty state (not a generic error, not a fake result) when there is no analysis backend',
    (tester) async {
      final photo = CapturedPhoto(
        localPath: '/tmp/photo.jpg',
        capturedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
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
