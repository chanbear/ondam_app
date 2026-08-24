import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/camera_permission_status.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_camera_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/providers/camera_permission_provider.dart';
import 'package:ondam_senior/features/home/presentation/pages/home_tab_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed permission state — avoids ever touching the real
/// `permission_handler` platform channel (not available in widget tests),
/// so this test exercises real Navigator push/pop mechanics, not plugin
/// behavior.
class _FixedCameraPermissionNotifier extends CameraPermissionNotifier {
  @override
  Future<CameraPermissionStatus> build() async => CameraPermissionStatus.denied;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  testWidgets(
    'tapping 문서 촬영 on the home tab enters the document scan screen, and back returns home',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraPermissionProvider.overrideWith(
              _FixedCameraPermissionNotifier.new,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(builder: (_) => const HomeTabPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('문서 읽기'), findsOneWidget);

      await tester.tap(find.text('문서 읽기'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentScanCameraPage), findsOneWidget);
      expect(find.text('카메라 권한 허용하기'), findsOneWidget);

      await tester.tap(find.text('뒤로'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentScanCameraPage), findsNothing);
      expect(find.byType(HomeTabPage), findsOneWidget);
    },
  );
}
