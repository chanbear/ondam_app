import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/message_check/presentation/widgets/manual_message_input_view.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  // `Clipboard.getData`/`setData` go through a real platform channel that
  // has no handler in the widget-test VM — without a mock, the call never
  // resolves and the test hangs forever instead of failing (observed: the
  // whole `flutter test` process blocked with 0% CPU). Mocking
  // SystemChannels.platform is the documented way to test clipboard
  // interaction without a device.
  String? clipboardText;

  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return clipboardText == null ? null : {'text': clipboardText};
          }
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('분석하기 button is disabled until text is entered', (tester) async {
    await tester.pumpWidget(wrap(ManualMessageInputView(onAnalyze: (_) {})));

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '분석하기'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'typing text enables 분석하기 and calls onAnalyze with the trimmed text',
    (tester) async {
      String? analyzed;
      await tester.pumpWidget(
        wrap(ManualMessageInputView(onAnalyze: (text) => analyzed = text)),
      );

      await tester.enterText(find.byType(TextField), '  의심스러운 문자 내용  ');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '분석하기'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(ElevatedButton, '분석하기'));

      expect(analyzed, '의심스러운 문자 내용');
    },
  );

  testWidgets('pasting from the clipboard fills the text field', (
    tester,
  ) async {
    clipboardText = '클립보드 문자 내용';

    await tester.pumpWidget(wrap(ManualMessageInputView(onAnalyze: (_) {})));

    await tester.tap(find.text('클립보드에서 붙여넣기'));
    await tester.pumpAndSettle();

    expect(find.text('클립보드 문자 내용'), findsOneWidget);
  });

  testWidgets(
    'an empty clipboard does not error — the field stays editable for manual entry',
    (tester) async {
      clipboardText = null;

      await tester.pumpWidget(wrap(ManualMessageInputView(onAnalyze: (_) {})));

      await tester.tap(find.text('클립보드에서 붙여넣기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), '직접 입력한 내용');
      expect(find.text('직접 입력한 내용'), findsOneWidget);
    },
  );
}
