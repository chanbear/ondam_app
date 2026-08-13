import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_preview_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_result_page.dart';

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
  late File tempFile;
  late CapturedPhoto photo;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('document_scan_test');
    tempFile = File('${dir.path}/photo.png');
    await tempFile.writeAsBytes(_onePixelPng);
    photo = CapturedPhoto(
      localPath: tempFile.path,
      capturedAt: DateTime(2026, 1, 1),
    );
  });

  tearDown(() async {
    if (tempFile.existsSync()) {
      await tempFile.parent.delete(recursive: true);
    }
  });

  testWidgets('shows retake and analyze actions for the captured photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: DocumentScanPreviewPage(photo: photo)),
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentScanPreviewPage(photo: photo),
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
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: DocumentScanPreviewPage(photo: photo)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('분석하기'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentScanResultPage), findsOneWidget);
  });
}
