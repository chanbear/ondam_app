import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../notification/presentation/providers/notifications_notifier.dart';
import '../providers/shell_tab_index_provider.dart';
import 'home_tab_page.dart';
import 'more_tab_page.dart';
import 'notification_tab_page.dart';
import 'records_tab_page.dart';
import 'statistics_tab_page.dart';

/// Guardian App의 메인 진입점(Auth 이후 첫 화면) — 하단 탭 5개(홈/알림/
/// 기록/통계/더보기)를 `IndexedStack`으로 전환한다. Senior 앱과 동일한
/// 구현 방식(go_router nested shell route 대신 지역 상태) — 이유는
/// `apps/senior/lib/features/home/presentation/pages/home_shell_page.dart`
/// 주석 참고. 탭 인덱스는 [shellTabIndexProvider]로 옮겨졌다 — 홈 탭의
/// "최근 알림 전체보기"처럼 다른 탭에서 특정 탭으로 전환할 수 있어야
/// 해서다(Guardian UI Application Round 1 §6).
class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key});

  static const _tabs = [
    HomeTabPage(),
    NotificationTabPage(),
    RecordsTabPage(),
    StatisticsTabPage(),
    MoreTabPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(shellTabIndexProvider);
    final unreadCount =
        ref
            .watch(notificationsProvider)
            .value
            ?.where((n) => !n.isRead)
            .length ??
        0;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: index, children: _tabs),
      ),
      bottomNavigationBar: AppBottomNavigation(
        items: [
          AppBottomNavItem(icon: Icons.home_outlined, label: l10n.navHome),
          AppBottomNavItem(
            icon: Icons.notifications_outlined,
            label: l10n.navNotification,
            badgeCount: unreadCount,
          ),
          AppBottomNavItem(icon: Icons.history, label: l10n.navRecords),
          AppBottomNavItem(
            icon: Icons.bar_chart_outlined,
            label: l10n.navStatistics,
          ),
          AppBottomNavItem(icon: Icons.more_horiz, label: l10n.navMore),
        ],
        currentIndex: index,
        onTap: (tapped) =>
            ref.read(shellTabIndexProvider.notifier).select(tapped),
      ),
    );
  }
}
