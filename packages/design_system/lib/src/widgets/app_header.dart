import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Shared screen header — title + back navigation as a text+arrow link
/// (never a bare icon), per ui-spec.md's existing "← 홈으로" pattern. Placed
/// at the top of `AppScaffold`, not a Flutter `AppBar`.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backLabel = '뒤로',
    this.actions = const [],
  });

  final String title;
  final VoidCallback? onBack;
  final String backLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (onBack != null)
            _BackLink(label: backLabel, onTap: onBack!)
          else
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
