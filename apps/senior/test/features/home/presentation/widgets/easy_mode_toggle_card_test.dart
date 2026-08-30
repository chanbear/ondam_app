import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ondam_senior/core/easy_mode/easy_mode_provider.dart';
import 'package:ondam_senior/features/home/presentation/widgets/easy_mode_toggle_card.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

/// ONDAM 2.0 요구사항 33 — 홈 화면에서 쉬운 모드 상태가 명확히 보이고,
/// 탭 한 번으로 켜고 끌 수 있어야 한다.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap() {
    return const ProviderScope(
      child: MaterialApp(
        locale: Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: EasyModeToggleCard()),
      ),
    );
  }

  testWidgets('꺼진 상태로 시작하고, Switch가 off를 보여준다', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('쉬운 모드'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('탭하면 easyModeProvider가 켜지고 Switch가 on으로 바뀐다', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.byType(EasyModeToggleCard));
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    final element = tester.element(find.byType(EasyModeToggleCard));
    final container = ProviderScope.containerOf(element);
    expect(container.read(easyModeProvider), isTrue);
  });
}
