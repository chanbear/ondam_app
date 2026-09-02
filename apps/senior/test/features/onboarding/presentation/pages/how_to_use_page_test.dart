import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/onboarding/presentation/pages/how_to_use_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

Widget _wrap() {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HowToUsePage(),
    ),
  );
}

// pop()이 실제로 이전 화면으로 돌아가는지 확인하려면 첫 화면(root route)이
// 아니라 push된 상태여야 한다.
Widget _wrapPushed() {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HowToUsePage())),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('첫 화면은 문서 읽기 안내를 보여주고 "다음"으로 다음 스텝으로 넘어간다', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('문서 읽기로 사기 확인하기'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('문자 확인하기'), findsOneWidget);
  });

  testWidgets('마지막 스텝에서는 "확인" 버튼을 누르면 화면을 닫는다', (tester) async {
    await tester.pumpWidget(_wrapPushed());
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }

    expect(find.text('내 기록 확인하기'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(HowToUsePage), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });
}
