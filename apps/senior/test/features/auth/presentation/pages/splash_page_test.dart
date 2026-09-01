import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ondam_senior/app/router/auth_routes.dart';
import 'package:ondam_senior/features/auth/presentation/pages/splash_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap() {
    final router = GoRouter(
      initialLocation: AuthRoutes.splash,
      routes: [
        GoRoute(path: AuthRoutes.splash, builder: (_, _) => const SplashPage()),
        GoRoute(
          path: AuthRoutes.phoneInput,
          builder: (_, _) => const Scaffold(body: Text('phone screen')),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  testWidgets('앱 이름과 시작 버튼을 보여준다', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('온담'), findsWidgets);
    expect(find.text('온담 시작하기'), findsOneWidget);
  });

  testWidgets('시작 버튼을 누르면 로그인 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('온담 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('phone screen'), findsOneWidget);
  });
}
