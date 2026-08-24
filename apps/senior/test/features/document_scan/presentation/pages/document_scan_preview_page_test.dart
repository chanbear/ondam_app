import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_preview_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_result_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/providers/document_scan_di_providers.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../domain/fakes/fake_analysis_repository.dart';

// Minimal 1x1 transparent PNG so Image.file has real bytes to decode.
const _onePixelPng = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  late Directory tempDir;
  late File tempFile;
  late File tempFile2;
  late CapturedPhoto photo;
  late CapturedPhoto photo2;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('document_scan_test');
    tempFile = File('${tempDir.path}/photo.png');
    await tempFile.writeAsBytes(_onePixelPng);
    tempFile2 = File('${tempDir.path}/photo2.png');
    await tempFile2.writeAsBytes(_onePixelPng);
    photo = CapturedPhoto(
      localPath: tempFile.path,
      capturedAt: DateTime(2026, 1, 1),
    );
    photo2 = CapturedPhoto(
      localPath: tempFile2.path,
      capturedAt: DateTime(2026, 1, 1, 0, 1),
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows retake and analyze actions for the captured photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DocumentScanPreviewPage(photos: [photo]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('재촬영'), findsWidgets);
    expect(find.text('분석하기'), findsOneWidget);
  });

  testWidgets('retake pops back to the previous (camera) screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentScanPreviewPage(photos: [photo]),
                    ),
                  ),
                  child: const Text('open preview'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open preview'));
    await tester.pumpAndSettle();
    expect(find.text('촬영 결과 확인'), findsOneWidget);

    await tester.tap(find.text('재촬영').first);
    await tester.pumpAndSettle();

    expect(find.text('open preview'), findsOneWidget);
    expect(find.text('촬영 결과 확인'), findsNothing);
  });

  testWidgets('analyze navigates to the result page', (tester) async {
    // Phase 8+: AnalysisRepositoryImpl now calls the real `analyze-document`
    // Edge Function (Supabase), so it needs an override here too — same
    // reasoning as message_check's equivalent widget test.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analysisRepositoryProvider.overrideWithValue(
            FakeAnalysisRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DocumentScanPreviewPage(photos: [photo]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('분석하기'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentScanResultPage), findsOneWidget);
  });

  group('ONDAM 2.0 요구사항 11 — 다중 문서 촬영', () {
    testWidgets('2장 이상으로 시작하면 개수와 사진이 모두 보인다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DocumentScanPreviewPage(photos: [photo, photo2]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('촬영한 문서 (2장)'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('삭제 버튼을 누르면 목록에서 제거되고 개수가 줄어든다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DocumentScanPreviewPage(photos: [photo, photo2]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('remove_photo_0')));
      await tester.pumpAndSettle();

      expect(find.text('촬영한 문서 (1장)'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('사진이 1장뿐이면 삭제할 수 없다(최소 1장 유지)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DocumentScanPreviewPage(photos: [photo]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('remove_photo_0')));
      await tester.pumpAndSettle();

      // onTap이 null이라 아무 일도 일어나지 않는다 — 여전히 1장.
      expect(find.text('촬영한 문서 (1장)'), findsOneWidget);
    });

    testWidgets('삭제 버튼의 실제 탭 영역이 접근성 최소 기준(44x44 논리 픽셀)을 만족한다'
        '(ONDAM 2.0 PHASE 31 — ui-design.md 접근성 규칙)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DocumentScanPreviewPage(photos: [photo, photo2]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const ValueKey('remove_photo_0')));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('분석하기를 누르면 현재 목록 전체가 결과 화면으로 전달된다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisRepositoryProvider.overrideWithValue(
              FakeAnalysisRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DocumentScanPreviewPage(photos: [photo, photo2]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('분석하기'));
      await tester.pumpAndSettle();

      final resultPage = tester.widget<DocumentScanResultPage>(
        find.byType(DocumentScanResultPage),
      );
      expect(resultPage.photos, hasLength(2));
    });
  });
}
