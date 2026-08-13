import 'package:flutter/material.dart';
import 'package:ondam_models/ondam_models.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Risk level shown as color + icon + text together (never color alone —
/// ui-principles.md Senior 6). Uses `AppColors.success/warning/error` — a
/// color family that [AppConfidenceIndicator] deliberately does NOT share,
/// so "risky content" and "uncertain AI answer" are never visually confused
/// (ui-research.md 9).
class AppRiskBadge extends StatelessWidget {
  const AppRiskBadge({super.key, required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (level) {
      RiskLevel.safe => (AppColors.success, Icons.check_circle, '안전'),
      RiskLevel.caution => (AppColors.warning, Icons.error_outline, '주의'),
      RiskLevel.dangerous => (AppColors.error, Icons.warning_amber, '위험 감지'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
