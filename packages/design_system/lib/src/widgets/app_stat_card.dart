import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Small number+label stat tile for Guardian's statistics screen (이번 달
/// 분석 수/위험 문자 수/일정 완료·잔여 등). Deliberately does not render a
/// chart — chart library selection is deferred to Phase 6
/// (ui-component-spec.md AppStatCard, Decision 3). Charts get their own
/// container built by the screen, not by this component.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
  });

  final String label;
  final String value;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.headlineMedium),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              trend!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
