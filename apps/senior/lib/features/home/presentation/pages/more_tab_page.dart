import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../connection/presentation/pages/guardian_list_page.dart';
import '../../../onboarding/presentation/pages/onboarding_flow_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../statistics/presentation/pages/fee_statistics_page.dart';
import '../../../support/presentation/pages/support_page.dart';
import '../providers/shell_tab_index_provider.dart';

/// 더보기 탭 — 내 정보/설정/연결된 보호자 목록/고객 지원/통계는 실제
/// 화면으로 연결한다. "알아두면 좋은 정보"는 별도 화면을 새로 만들지 않고
/// 이미 실제 데이터(`search-benefit-services`)로 채워진 "정보" 탭(index 0)
/// 으로 전환한다 — `docs/product/user-flow.md` "[더보기] → 알아두면 좋은
/// 정보"가 "[정보] → 알아두면 좋은 정보(맞춤 카드 3개)"와 같은 항목을
/// 가리키는 문서 구조를 그대로 반영한 것(Guardian의 "전체보기" 탭 전환과
/// 동일한 `shellTabIndexProvider` 패턴).
///
/// 2026-08-28 — Easy 모드에서는 얇은 세로 리스트가 화면 대비 휑해 보인다는
/// 사용자 피드백(ui-prototype `easy.more`에서 이미 확인/수정됨)으로, 같은
/// `items` 목록을 2열 큰 타일 그리드로 다시 배치한다. Normal 모드는
/// ui-prototype `S("more")`에 맞춰 계정/이용 정보/설정 3개 섹션의 구분선
/// 리스트로(2026-08-30) — Easy와 마찬가지로 `items`의 항목/순서/이동
/// 대상은 완전히 동일, 레이아웃(섹션 묶음 vs 타일 그리드)만 분기한다.
class MoreTabPage extends ConsumerWidget {
  const MoreTabPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    // 순서는 HTML prototype `more()`을 기준으로, 이번 phase 지시(§3)의
    // 정보/사용법 → 고객지원 → 설정(마지막) 순서를 반영한다.
    final items = <(IconData, String, VoidCallback)>[
      (
        Icons.person_outline,
        l10n.profileTitle,
        () => _push(context, const ProfilePage()),
      ),
      (
        Icons.family_restroom_outlined,
        l10n.guardianListTitle,
        () => _push(context, const GuardianListPage()),
      ),
      (
        Icons.bar_chart_outlined,
        l10n.statisticsLabel,
        () => _push(context, const FeeStatisticsPage()),
      ),
      (
        Icons.lightbulb_outline,
        l10n.usefulInfoLabel,
        () => ref.read(shellTabIndexProvider.notifier).select(0),
      ),
      (
        Icons.menu_book_outlined,
        l10n.howToUseLabel,
        () => _push(context, const OnboardingFlowPage()),
      ),
      (
        Icons.support_agent_outlined,
        l10n.supportTitle,
        () => _push(context, const SupportPage()),
      ),
      (
        Icons.settings_outlined,
        l10n.settingsTitle,
        () => _push(context, const SettingsPage()),
      ),
      // ui-prototype `S("more")`는 "설정"과 별도로 "접근성 설정" 행을 둔다.
      // 실제 앱은 접근성 항목(글자 크기/음성 안내/언어)을 별도 화면으로
      // 쪼개지 않고 `SettingsPage` 안에 이미 포함하기로 한 기존 결정을
      // 유지하되(설정 페이지 여러 개로 쪼개지 않음), 목록에서 바로 찾을 수
      // 있도록 같은 화면으로 가는 행을 하나 더 둔다.
      (
        Icons.accessibility_new_outlined,
        l10n.accessibilitySettingsTitle,
        () => _push(context, const SettingsPage()),
      ),
    ];

    if (!easyMode) {
      // ui-prototype `S("more")`처럼 카드 그리드가 아니라 계정/이용 정보/
      // 설정 3개 섹션으로 묶은 구분선 리스트 행으로 보여준다(2026-08-30
      // 정렬). 항목/순서/이동 대상은 그대로 — 섹션 묶음만 바뀐다. "알아두면
      // 좋은 정보"/"사용 방법 안내"/"고객 지원"은 prototype에 없는 항목이지만
      // 실제 앱에 이미 있는 기능이라(제거는 요구사항 밖) "이용 정보" 섹션에
      // 함께 둔다.
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          AppSectionHeader(title: l10n.moreTitle),
          const SizedBox(height: AppSpacing.sm),
          AppSectionHeader(title: l10n.moreAccountSectionTitle),
          for (final (icon, label, onTap) in items.take(2))
            _MoreListRow(icon: icon, label: label, onTap: onTap),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(title: l10n.moreUsageInfoSectionTitle),
          for (final (icon, label, onTap) in items.skip(2).take(4))
            _MoreListRow(icon: icon, label: label, onTap: onTap),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(title: l10n.settingsTitle),
          for (final (icon, label, onTap) in items.skip(6))
            _MoreListRow(icon: icon, label: label, onTap: onTap),
          const SizedBox(height: AppSpacing.xl),
          // ui-prototype `S("more")` — 로그아웃은 설정 화면 안이 아니라 More
          // 화면 자체 맨 아래 독립 행으로 둔다(danger 톤). 실제 로그아웃
          // 로직/Provider 정리는 `SettingsPage`와 동일한
          // `signOutAndClearSession`을 그대로 재사용한다.
          _MoreListRow(
            icon: Icons.logout,
            label: l10n.logout,
            onTap: () => signOutAndClearSession(ref),
            danger: true,
          ),
        ],
      );
    }

    return GridView.count(
      padding: const EdgeInsets.all(AppSpacing.lg),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.05,
      children: [
        for (final (icon, label, onTap) in items)
          _EasyMoreTile(icon: icon, label: label, onTap: onTap),
      ],
    );
  }
}

/// ui-prototype `T.listRow` — 아이콘(연한 tint 원) + 라벨 + chevron,
/// 카드 박스 대신 하단 구분선으로만 항목을 나눈다.
class _MoreListRow extends StatelessWidget {
  const _MoreListRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tintColor = danger ? AppColors.errorSoft : AppColors.primarySoft;
    final iconColor = danger ? AppColors.error : AppColors.primary;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppTouch.standard),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: tintColor,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: danger ? AppColors.error : null,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EasyMoreTile extends StatelessWidget {
  const _EasyMoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      // 2026-08-30 — ui-prototype `.easy-tile`와 동일한 흰 배경 위 흰
      // 타일 대비 부족 문제(오늘 easy-btn/HomeFeatureLargeButton에 이미
      // 적용한 수정)가 이 타일에도 그대로 있었다 — surface(흰색) 대신
      // primarySoft로. 안의 아이콘은 solid-primary라 겹치지 않는다.
      child: Material(
        color: AppColors.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
