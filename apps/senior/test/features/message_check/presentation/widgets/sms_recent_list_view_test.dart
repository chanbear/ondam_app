import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/sms_inbox_notifier.dart';
import 'package:ondam_senior/features/message_check/presentation/widgets/sms_recent_list_view.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

class _FixedSmsInboxNotifier extends SmsInboxNotifier {
  _FixedSmsInboxNotifier(this._build);
  final Future<List<SmsMessage>> Function() _build;

  @override
  Future<List<SmsMessage>> build() => _build();
}

void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
  testWidgets(
    'shows a plain-language empty state for an empty inbox — never a fake message',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            smsInboxProvider.overrideWith(
              () => _FixedSmsInboxNotifier(() async => const <SmsMessage>[]),
            ),
          ],
          child: wrap(const SmsRecentListView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('최근 받은 문자가 없어요.'), findsOneWidget);
    },
  );

  testWidgets('shows a retryable error state on a platform/read failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smsInboxProvider.overrideWith(
            () => _FixedSmsInboxNotifier(
              () async => throw const UnknownFailure('최근 문자를 불러오지 못했어요.'),
            ),
          ),
        ],
        child: wrap(const SmsRecentListView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('최근 문자를 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('renders every message in the inbox as a tile', (tester) async {
    final messages = [
      SmsMessage(sender: 'A', body: '첫 번째', receivedAt: DateTime(2026, 1, 1)),
      SmsMessage(sender: 'B', body: '두 번째', receivedAt: DateTime(2026, 1, 2)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smsInboxProvider.overrideWith(
            () => _FixedSmsInboxNotifier(() async => messages),
          ),
        ],
        child: wrap(const SmsRecentListView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('첫 번째'), findsOneWidget);
    expect(find.text('두 번째'), findsOneWidget);
  });
}
