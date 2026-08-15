import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

void main() {
  const items = [
    AppBottomNavItem(icon: Icons.info_outline, label: '정보'),
    AppBottomNavItem(icon: Icons.home_outlined, label: '홈'),
  ];

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(bottomNavigationBar: child));

  testWidgets('large가 false면 탭 개수/라벨은 그대로 유지된다', (tester) async {
    await tester.pumpWidget(
      wrap(AppBottomNavigation(items: items, currentIndex: 0, onTap: (_) {})),
    );

    expect(find.text('정보'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.height, isNull);
  });

  testWidgets('large가 true면 탭 구성은 그대로지만 아이콘/높이가 커진다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppBottomNavigation(
          items: items,
          currentIndex: 0,
          onTap: (_) {},
          large: true,
        ),
      ),
    );

    expect(find.text('정보'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.height, AppEasyMode.navBarHeight);

    final icon = tester.widget<Icon>(find.byIcon(Icons.home_outlined));
    expect(icon.size, 24 * AppEasyMode.navIconScale);
  });
}
