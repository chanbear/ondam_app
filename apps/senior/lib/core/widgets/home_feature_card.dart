import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// Data for a single core-feature entry point (문서 촬영, 문자 확인 등).
/// Shared across features that need the same full-width entry-button style —
/// originally Home's Normal Mode feature-row list and Easy Mode's large-button
/// list, now also feature start pages (e.g. document_scan) that show the same
/// "large primary-soft button" for their Easy Mode CTA.
/// [subtitle]은 ui-prototype `S("home")`의 `feature-card.row`가 보여주는
/// 한 줄 설명 — Normal Mode 행에서만 쓰이고(Easy Mode는 라벨만), 없으면
/// [HomeFeatureLargeButton]이 라벨만 크게 보여준다.
class HomeFeatureItem {
  const HomeFeatureItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback onTap;
}

/// 아이콘 + 라벨(+선택적 서브텍스트) 전체너비 행 — ui-prototype
/// `feature-card.row`(Normal Mode, 서브텍스트+chevron 있음)와 `easy-btn`
/// (Easy Mode, 굵은 라벨만·chevron 없음) 둘 다 이 하나의 위젯으로 표현한다:
/// [subtitle]이 있으면 Normal 행 스타일, null이면 Easy 큰 버튼 스타일이
/// 되고 [showChevron]으로 화살표 유무를 맞춘다.
class HomeFeatureLargeButton extends StatelessWidget {
  const HomeFeatureLargeButton({
    super.key,
    required this.item,
    this.subtitle,
    this.showChevron = true,
  });

  final HomeFeatureItem item;
  final String? subtitle;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final label = subtitle == null
        ? Text(item.label, style: AppTextStyles.headlineMedium)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.label, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        // 2026-08-30 — ui-prototype `.easy-btn` 오늘자 수정(배경 #fff →
        // --primary-soft, 조원 피드백: 흰 배경 위 흰 버튼이 안 보임)을 그대로
        // 이식. Easy Mode 변형(subtitle==null)만 옅은 블루 배경으로 화면
        // 배경과 대비를 주고, Normal Mode 행(`.feature-card`, 원래 흰 배경
        // 유지)은 그대로 둔다.
        color: subtitle == null ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: item.iconColor,
                  child: Icon(item.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: label),
                if (showChevron) const Icon(Icons.chevron_right, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
