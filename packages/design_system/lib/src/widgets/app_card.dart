import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// `selected` matches the Phase 42-approved HTML prototype's `.elder-chip.active`
/// pattern (primary border + tinted surface — never an isolated color change).
/// `unread` matches `.notif-card.unread` (4px primary left accent) — the
/// caller must still show the "안읽음" state as icon/text too, this only
/// supplies the shared visual accent (ui-principles.md "색상만으로 전달 금지").
enum AppCardVariant { normal, selected, unread }

/// Shared card container — white/surface background, token-based padding and
/// corner radius, used for the list-item card pattern seen throughout the
/// reference app (아이콘 + 텍스트 + 우측 액션).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.variant = AppCardVariant.normal,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final border = switch (variant) {
      AppCardVariant.normal => Border.all(color: AppColors.border),
      AppCardVariant.selected => Border.all(color: AppColors.primary, width: 2),
      AppCardVariant.unread => Border(
        left: const BorderSide(color: AppColors.primary, width: 4),
        top: BorderSide(color: AppColors.border),
        right: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
      ),
    };
    final fillColor = variant == AppCardVariant.selected
        ? AppColors.primary.withValues(alpha: 0.06)
        : Theme.of(context).colorScheme.surface;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        border: border,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
