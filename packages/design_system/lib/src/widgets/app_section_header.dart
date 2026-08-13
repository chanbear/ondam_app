import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Section title used at the top of a list/group within a screen — keeps
/// spacing/typography consistent instead of each screen hardcoding
/// `Text(style: ...)` + `SizedBox`.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
          ?trailing,
        ],
      ),
    );
  }
}
