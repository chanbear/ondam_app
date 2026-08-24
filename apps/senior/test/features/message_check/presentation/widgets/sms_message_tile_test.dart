import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/presentation/widgets/sms_message_tile.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('shows the sender and a body preview', (tester) async {
    final message = SmsMessage(
      sender: '010-1234-5678',
      body: '[Web발신] 안전 안내문자입니다.',
      receivedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap(SmsMessageTile(message: message)));

    expect(find.text('010-1234-5678'), findsOneWidget);
    expect(find.text('[Web발신] 안전 안내문자입니다.'), findsOneWidget);
  });

  testWidgets('falls back to a plain-language label when sender is unknown', (
    tester,
  ) async {
    final message = SmsMessage(
      sender: null,
      body: '내용',
      receivedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap(SmsMessageTile(message: message)));

    expect(find.text('알 수 없는 번호'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    final message = SmsMessage(
      sender: '010-0000-0000',
      body: '내용',
      receivedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      wrap(SmsMessageTile(message: message, onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(SmsMessageTile));

    expect(tapped, isTrue);
  });
}
