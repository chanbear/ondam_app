import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/home/presentation/pages/home_tab_page.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_permission_status.dart';
import 'package:ondam_senior/features/message_check/presentation/pages/message_check_entry_page.dart';
import 'package:ondam_senior/features/message_check/presentation/pages/message_risk_result_page.dart';
import 'package:ondam_senior/features/message_check/presentation/pages/sms_message_detail_page.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/message_check_di_providers.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/sms_inbox_notifier.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/sms_permission_provider.dart';
import 'package:ondam_senior/features/message_check/presentation/widgets/manual_message_input_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/fakes/fake_message_risk_repository.dart';

/// Fixed permission state — avoids ever touching the real
/// `permission_handler` platform channel, mirrors
/// `document_scan_navigation_test.dart`'s `_FixedCameraPermissionNotifier`.
class _FixedSmsPermissionNotifier extends SmsPermissionNotifier {
  _FixedSmsPermissionNotifier(this._status);
  final SmsPermissionStatus _status;

  @override
  Future<SmsPermissionStatus> build() async => _status;
}

class _FixedSmsInboxNotifier extends SmsInboxNotifier {
  _FixedSmsInboxNotifier(this._messages);
  final List<SmsMessage> _messages;

  @override
  Future<List<SmsMessage>> build() async => _messages;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  testWidgets(
    'tapping 문자 확인 on the home tab enters message check, and back returns home',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            smsPermissionProvider.overrideWith(
              () => _FixedSmsPermissionNotifier(SmsPermissionStatus.denied),
            ),
          ],
          child: const MaterialApp(home: HomeTabPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('문자 확인'), findsOneWidget);

      await tester.tap(find.text('문자 확인'));
      await tester.pumpAndSettle();

      expect(find.byType(MessageCheckEntryPage), findsOneWidget);
      expect(find.text('문자 권한 허용하기'), findsOneWidget);

      await tester.tap(find.text('뒤로'));
      await tester.pumpAndSettle();

      expect(find.byType(MessageCheckEntryPage), findsNothing);
      expect(find.byType(HomeTabPage), findsOneWidget);
    },
  );

  testWidgets('permanentlyDenied shows a settings-open path, not a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smsPermissionProvider.overrideWith(
            () => _FixedSmsPermissionNotifier(
              SmsPermissionStatus.permanentlyDenied,
            ),
          ),
        ],
        child: const MaterialApp(home: MessageCheckEntryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정 열기'), findsOneWidget);
    expect(find.text('문자 권한 허용하기'), findsNothing);
  });

  testWidgets(
    'unsupported (e.g. iOS) shows the manual paste/입력 flow directly, never a permission prompt',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            smsPermissionProvider.overrideWith(
              () =>
                  _FixedSmsPermissionNotifier(SmsPermissionStatus.unsupported),
            ),
          ],
          child: const MaterialApp(home: MessageCheckEntryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ManualMessageInputView), findsOneWidget);
      expect(find.text('문자 권한 허용하기'), findsNothing);
    },
  );

  testWidgets(
    'granted shows the recent-message list, and selecting one flows through detail into analysis',
    (tester) async {
      final message = SmsMessage(
        sender: '010-1234-5678',
        body: '[Web발신] 계좌가 정지되었습니다.',
        receivedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            smsPermissionProvider.overrideWith(
              () => _FixedSmsPermissionNotifier(SmsPermissionStatus.granted),
            ),
            smsInboxProvider.overrideWith(
              () => _FixedSmsInboxNotifier([message]),
            ),
            // Phase 8: analysis now calls the real Edge Function (Supabase)
            // — override with a fake so this navigation test doesn't need a
            // live backend. Default result (Err(UnavailableFailure())) keeps
            // this test's original assertion unchanged.
            messageRiskRepositoryProvider.overrideWithValue(
              FakeMessageRiskRepository()
                ..result = const Err(
                  UnavailableFailure('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'),
                ),
            ),
          ],
          child: const MaterialApp(home: MessageCheckEntryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('010-1234-5678'), findsOneWidget);

      await tester.tap(find.text('010-1234-5678'));
      await tester.pumpAndSettle();

      expect(find.byType(SmsMessageDetailPage), findsOneWidget);
      expect(find.text('[Web발신] 계좌가 정지되었습니다.'), findsOneWidget);

      await tester.tap(find.text('분석하기'));
      await tester.pumpAndSettle();

      expect(find.byType(MessageRiskResultPage), findsOneWidget);
      expect(find.text('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'), findsOneWidget);
    },
  );
}
