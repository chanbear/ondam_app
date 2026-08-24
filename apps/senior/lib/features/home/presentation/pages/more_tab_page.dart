import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/widgets/coming_soon_page.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../connection/presentation/pages/guardian_list_page.dart';
import '../../../onboarding/presentation/pages/onboarding_flow_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../statistics/presentation/pages/fee_statistics_page.dart';
import '../../../support/presentation/pages/support_page.dart';

/// 더보기 탭 — 내 정보/설정/연결된 보호자 목록/고객 지원/통계(PHASE 37)는
/// 실제 화면으로 연결하고, 아직 도메인 계층이 없는 "알아두면 좋은 정보"만
/// `ComingSoonPage`로 보낸다.
class MoreTabPage extends StatelessWidget {
  const MoreTabPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 순서는 HTML prototype `more()`을 기준으로, 이번 phase 지시(§3)의
    // 정보/사용법 → 고객지원 → 설정(마지막) 순서를 반영한다.
    final items = <(IconData, String, Widget Function())>[
      (Icons.person_outline, l10n.profileTitle, () => const ProfilePage()),
      (
        Icons.family_restroom_outlined,
        l10n.guardianListTitle,
        () => const GuardianListPage(),
      ),
      (
        Icons.bar_chart_outlined,
        l10n.statisticsLabel,
        () => const FeeStatisticsPage(),
      ),
      (
        Icons.lightbulb_outline,
        l10n.usefulInfoLabel,
        () => ComingSoonPage(title: l10n.usefulInfoLabel),
      ),
      (
        Icons.menu_book_outlined,
        l10n.howToUseLabel,
        () => const OnboardingFlowPage(),
      ),
      (
        Icons.support_agent_outlined,
        l10n.supportTitle,
        () => const SupportPage(),
      ),
      (Icons.settings_outlined, l10n.settingsTitle, () => const SettingsPage()),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppSectionHeader(title: l10n.moreTitle),
        for (final (icon, label, pageBuilder) in items)
          AppCard(
            onTap: () => _push(context, pageBuilder()),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
