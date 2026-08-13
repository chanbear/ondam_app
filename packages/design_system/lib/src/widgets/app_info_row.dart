import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// One key-value or checklist line — profile fields, bill line items,
/// "확인할 일" checklists all repeat this layout (ui-component-spec.md
/// AppInfoRow). Pass [checked]/[onCheckedChanged] for the checklist variant,
/// [value] for the key-value variant — not both at once.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    this.value,
    this.checked,
    this.onCheckedChanged,
  });

  final String label;
  final String? value;
  final bool? checked;
  final ValueChanged<bool?>? onCheckedChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          if (checked != null)
            Checkbox(value: checked, onChanged: onCheckedChanged),
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          if (value != null)
            Text(
              value!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
