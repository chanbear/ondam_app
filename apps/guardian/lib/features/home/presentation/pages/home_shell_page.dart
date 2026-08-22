import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import 'home_tab_page.dart';
import 'more_tab_page.dart';
import 'notification_tab_page.dart';
import 'records_tab_page.dart';
import 'statistics_tab_page.dart';

/// Guardian App의 메인 진입점(Auth 이후 첫 화면) — 하단 탭 5개(홈/알림/
/// 기록/통계/더보기)를 로컬 `IndexedStack`으로 전환한다. Senior 앱과 동일한
/// 구현 방식(go_router nested shell route 대신 지역 상태) — 이유는
/// `apps/senior/lib/features/home/presentation/pages/home_shell_page.dart`
/// 주석 참고.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;

  static const _tabs = [
    HomeTabPage(),
    NotificationTabPage(),
    RecordsTabPage(),
    StatisticsTabPage(),
    MoreTabPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: AppBottomNavigation(
        items: [
          AppBottomNavItem(icon: Icons.home_outlined, label: l10n.navHome),
          AppBottomNavItem(
            icon: Icons.notifications_outlined,
            label: l10n.navNotification,
          ),
          AppBottomNavItem(icon: Icons.history, label: l10n.navRecords),
          AppBottomNavItem(
            icon: Icons.bar_chart_outlined,
            label: l10n.navStatistics,
          ),
          AppBottomNavItem(icon: Icons.more_horiz, label: l10n.navMore),
        ],
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
