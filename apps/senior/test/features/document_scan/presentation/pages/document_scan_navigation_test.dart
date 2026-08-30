import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/camera_permission_status.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_camera_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/pages/document_scan_start_page.dart';
import 'package:ondam_senior/features/document_scan/presentation/providers/camera_permission_provider.dart';
import 'package:ondam_senior/features/home/presentation/pages/home_tab_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fixed permission state — avoids ever touching the real
/// `permission_handler` platform channel (not available in widget tests),
/// so this test exercises real Navigator push/pop mechanics, not plugin
/// behavior.
class _FixedCameraPermissionNotifier extends CameraPermissionNotifier {
  @override
  Future<CameraPermissionStatus> build() async => CameraPermissionStatus.denied;
}

void main() {
  // 2026-08-30 — `onboardingStatusProvider`가 계정별 키로 스코프되며
  // `authStateChangesProvider`(→ `supabaseClientProvider`)를 watch하게
  // 됐다 — `HomeTabPage`를 그리는 위젯 테스트는 `widget_test.dart`와 같은
  // 더미 Supabase 초기화가 필요하다(세션 없음 → 기존 미스코프 키로 폴백,
  // 동작은 그대로).
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  testWidgets(
    'tapping 문서 읽기 on the home tab enters the document scan start screen, '
    '촬영하기 enters the camera screen, and back returns home step by step',
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
            home: const Scaffold(body: HomeTabPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('문서 읽기'), findsOneWidget);

      await tester.tap(find.text('문서 읽기'));
      await tester.pumpAndSettle();

      // ui-prototype `S("doc-start")` — 홈에서 곧장 카메라로 가지 않고
      // 촬영하기/불러오기 진입 화면을 먼저 거친다.
      expect(find.byType(DocumentScanStartPage), findsOneWidget);
      expect(find.text('사진 촬영하기'), findsOneWidget);
      expect(find.text('사진 불러오기'), findsOneWidget);

      await tester.tap(find.text('사진 촬영하기'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentScanCameraPage), findsOneWidget);
      expect(find.text('카메라 권한 허용하기'), findsOneWidget);

      await tester.tap(find.text('뒤로'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentScanCameraPage), findsNothing);
      expect(find.byType(DocumentScanStartPage), findsOneWidget);

      await tester.tap(find.text('뒤로'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentScanStartPage), findsNothing);
      expect(find.byType(HomeTabPage), findsOneWidget);
    },
  );
}
