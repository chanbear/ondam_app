import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/widgets/coming_soon_page.dart';
import '../../../connection/presentation/pages/guardian_list_page.dart';
import '../../../onboarding/presentation/pages/onboarding_flow_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../support/presentation/pages/support_page.dart';

/// 더보기 탭 — 내 정보/설정/연결된 보호자 목록/고객 지원은 실제 화면으로
/// 연결하고, 아직 도메인 계층이 없는 항목(통계/알아두면 좋은 정보)은
/// `ComingSoonPage`로 보낸다.
class MoreTabPage extends StatelessWidget {
  const MoreTabPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Widget Function())>[
      (Icons.person_outline, '내 정보', () => const ProfilePage()),
      (
        Icons.family_restroom_outlined,
        '연결된 보호자 목록',
        () => const GuardianListPage(),
      ),
      (Icons.bar_chart_outlined, '통계', () => const ComingSoonPage(title: '통계')),
      (
        Icons.lightbulb_outline,
        '알아두면 좋은 정보',
        () => const ComingSoonPage(title: '알아두면 좋은 정보'),
      ),
      (Icons.menu_book_outlined, '사용 방법 안내', () => const OnboardingFlowPage()),
      (Icons.settings_outlined, '설정', () => const SettingsPage()),
      (Icons.support_agent_outlined, '고객 지원', () => const SupportPage()),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppSectionHeader(title: '더보기'),
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
