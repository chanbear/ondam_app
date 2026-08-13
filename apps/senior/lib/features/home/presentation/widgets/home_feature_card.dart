import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// Data for a single core-feature entry point on the home screen (문서 촬영,
/// 문자 확인 등). Shared between Normal Mode's card grid and Easy Mode's
/// large-button list so both read from the same source list.
class HomeFeatureItem {
  const HomeFeatureItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
}

/// Normal Mode card — icon-in-circle + label, per ui-spec.md's existing
/// "원형 컬러 배경 + 흰 아이콘" pattern.
class HomeFeatureCard extends StatelessWidget {
  const HomeFeatureCard({super.key, required this.item});

  final HomeFeatureItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: item.iconColor,
            child: Icon(item.icon, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Easy Mode button — same icon+label but as a big, full-width tappable row
/// (ui-principles.md "큰 터치 영역", "아이콘 + 텍스트 조합을 항상 함께").
class HomeFeatureLargeButton extends StatelessWidget {
  const HomeFeatureLargeButton({super.key, required this.item});

  final HomeFeatureItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                Expanded(
                  child: Text(item.label, style: AppTextStyles.titleMedium),
                ),
                const Icon(Icons.chevron_right, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
