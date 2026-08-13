import 'package:flutter/material.dart';
import 'package:ondam_models/ondam_models.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Card-form risk callout — color + icon + text together (same color family
/// as `AppRiskBadge`, just a bigger card instead of a small pill). Used for
/// message/document analysis results, guardian alert detail, and abnormal
/// bill-amount highlights (ui-component-spec.md AppAlertCard).
class AppAlertCard extends StatelessWidget {
  const AppAlertCard({
    super.key,
    required this.level,
    required this.title,
    this.description,
  });

  final RiskLevel level;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (level) {
      RiskLevel.safe => (AppColors.success, Icons.check_circle),
      RiskLevel.caution => (AppColors.warning, Icons.error_outline),
      RiskLevel.dangerous => (AppColors.error, Icons.warning_amber),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(color: color),
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(description!, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
