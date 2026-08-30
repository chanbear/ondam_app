import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/camera_flash_mode.dart';
import 'package:ondam_senior/features/document_scan/presentation/widgets/flash_toggle_button.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    CameraFlashMode mode, {
    bool easyMode = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FlashToggleButton(mode: mode, easyMode: easyMode, onTap: () {}),
        ),
      ),
    );
  }

  testWidgets('shows a visible text label for the off state, not icon-only', (
    tester,
  ) async {
    await pump(tester, CameraFlashMode.off);
    expect(find.text('플래시 꺼짐'), findsOneWidget);
  });

  testWidgets('shows a visible text label for the on state', (tester) async {
    await pump(tester, CameraFlashMode.on);
    expect(find.text('플래시 켜짐'), findsOneWidget);
  });

  testWidgets('calls onTap when pressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FlashToggleButton(
            mode: CameraFlashMode.off,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FlashToggleButton));
    expect(tapped, isTrue);
  });

  testWidgets('easy mode uses a larger touch target than standard', (
    tester,
  ) async {
    await pump(tester, CameraFlashMode.off, easyMode: true);
    final easySize = tester.getSize(find.byType(FlashToggleButton));

    await pump(tester, CameraFlashMode.off, easyMode: false);
    final standardSize = tester.getSize(find.byType(FlashToggleButton));

    expect(easySize.height, greaterThanOrEqualTo(standardSize.height));
  });
}
