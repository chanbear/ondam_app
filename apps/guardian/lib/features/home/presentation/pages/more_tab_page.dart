import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/widgets/coming_soon_page.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../connection/presentation/pages/connection_list_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

/// 더보기 탭 — 설정/다른 어르신 연결은 실제 화면으로 연결하고, 고객 지원은
/// 아직 도메인 계층이 없어 `ComingSoonPage`로 보낸다. "어르신 앱 열기"는
/// Decision 1에 따라 채택하지 않으므로 메뉴에 넣지 않는다.
class MoreTabPage extends StatelessWidget {
  const MoreTabPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(IconData, String, Widget Function())>[
      (
        Icons.person_add_alt_outlined,
        l10n.connectAnotherElderAction,
        () => const ConnectionListPage(),
      ),
      (Icons.settings_outlined, l10n.settingsTitle, () => const SettingsPage()),
      (
        Icons.support_agent_outlined,
        l10n.supportTitle,
        () => ComingSoonPage(title: l10n.supportTitle),
      ),
    ];

    // Home P0(Guardian UI Application Round 1)와 동일한 원인 — IndexedStack
    // 자식으로 ListView를 곧바로 반환하면 최초 프레임(뷰포트 메트릭 도착
    // 전 0x0 constraint)에 레이아웃이 굳어 본문이 비어버릴 수 있다. 다른
    // 탭들처럼 Expanded로 명시적 bounded height를 준다.
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppSectionHeader(title: l10n.navMore),
              for (final (icon, label, pageBuilder) in items)
                AppCard(
                  onTap: () => _push(context, pageBuilder()),
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(label, style: AppTextStyles.bodyLarge),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }
}
