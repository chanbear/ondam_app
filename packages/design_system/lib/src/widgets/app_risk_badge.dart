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
///
/// [label] is passed in already localized by the caller — this package has
/// no `AppLocalizations` of its own (senior/guardian each generate their
/// own), so it follows the same convention as [AppAlertCard]/[AppStatusCard]
/// (message/title params, no strings baked in here).
class AppRiskBadge extends StatelessWidget {
  const AppRiskBadge({super.key, required this.level, required this.label});

  final RiskLevel level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (level) {
      RiskLevel.safe => (AppColors.success, Icons.check_circle),
      RiskLevel.caution => (AppColors.warning, Icons.error_outline),
      RiskLevel.dangerous => (AppColors.error, Icons.warning_amber),
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
