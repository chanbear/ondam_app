import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import 'app_icon_button.dart';

/// Labeled numeric stepper — center value with a decrease/increase button on
/// either side. Used where typing a number by hand (e.g. age) is harder than
/// tapping arrows a few times. Bounds and labels are supplied by the caller,
/// this widget only renders (validation/persistence stay in the feature).
class AppNumberStepper extends StatelessWidget {
  const AppNumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.decreaseSemanticLabel,
    required this.increaseSemanticLabel,
    this.min = 0,
    this.max = 120,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String decreaseSemanticLabel;
  final String increaseSemanticLabel;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > min;
    final canIncrease = value < max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppIconButton(
                icon: Icons.remove,
                semanticLabel: decreaseSemanticLabel,
                onPressed: canDecrease ? () => onChanged(value - 1) : null,
              ),
              Text('$value', style: AppTextStyles.displayLarge),
              AppIconButton(
                icon: Icons.add,
                semanticLabel: increaseSemanticLabel,
                onPressed: canIncrease ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
