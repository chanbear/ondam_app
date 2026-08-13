import 'package:flutter/material.dart';
import 'package:ondam_models/ondam_models.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// AI reliability shown as a plain-language sentence — never a number or
/// percentage (ui-spec.md "답변 신뢰도 표시", confirmed again in
/// ui-research.md 9). Place at the TOP of a result screen, before the
/// original text/summary, so the user knows how much to trust the answer
/// before reading it. Deliberately never uses `AppColors.error` — that is
/// reserved for [AppRiskBadge]'s risk color family, so "I'm not sure I read
/// this right" is never visually confused with "this content is dangerous".
class AppConfidenceIndicator extends StatelessWidget {
  const AppConfidenceIndicator({super.key, required this.level});

  final ReliabilityLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (level) {
      ReliabilityLevel.high => (
        '이 답변은 비교적 확실해요.',
        Icons.check_circle_outline,
        AppColors.primary,
      ),
      ReliabilityLevel.medium => (
        '조금 더 확인이 필요해요.',
        Icons.help_outline,
        AppColors.textSecondary,
      ),
      ReliabilityLevel.low => (
        '정확하지 않을 수 있어요.',
        Icons.info_outline,
        AppColors.textSecondary,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
