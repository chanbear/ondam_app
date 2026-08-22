import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// "Everything at a glance" summary card at the top of a home screen —
/// Senior's "오늘 해야 할 일" summary, Guardian's "오늘의 안심 상태" banner
/// (ui-component-spec.md AppStatusCard). Not a risk indicator by itself —
/// pass [accentColor] (e.g. from the same family as `AppRiskBadge`) when the
/// status reflects a risk level.
class AppStatusCard extends StatelessWidget {
  const AppStatusCard({
    super.key,
    required this.message,
    this.description,
    this.icon,
    this.accentColor,
    this.messageMaxLines,
  });

  final String message;
  final String? description;
  final IconData? icon;
  final Color? accentColor;

  /// Null (default) keeps the previous unclamped behavior — see
  /// `AppAlertCard.titleMaxLines` for the same rationale.
  final int? messageMaxLines;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: AppTextStyles.titleMedium,
                  maxLines: messageMaxLines,
                  overflow: messageMaxLines != null
                      ? TextOverflow.ellipsis
                      : null,
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
