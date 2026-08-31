import 'package:flutter/material.dart';
import 'package:ondam_models/ondam_models.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// AI가 실제로 계산한 확률이 아니라 신뢰도 수준(high/medium/low)을
/// 사용자가 이해하기 쉬운 퍼센트로 시각화한 "표시값"이다 — 실제 모델
/// confidence score가 아니다(ONDAM 2.0 요구사항 13/22). 백엔드가 실제
/// 확률을 제공하게 되면 이 매핑을 그 값으로 교체해야 한다.
extension ReliabilityLevelDisplay on ReliabilityLevel {
  int get displayPercent => switch (this) {
    ReliabilityLevel.high => 90,
    ReliabilityLevel.medium => 70,
    ReliabilityLevel.low => 40,
  };
}

/// AI reliability — 기본은 문장 하나만(never a number or percentage per
/// ui-spec.md "답변 신뢰도 표시", ui-research.md 9). [showPercentage]가
/// true면 ONDAM 2.0 요구사항 13/22에 따라 "답변 신뢰도 90%"처럼 매핑된
/// 표시용 퍼센트를 문장과 함께 보여준다 — 기본값 false로 기존 화면(Guardian
/// 등)의 동작은 그대로 유지된다. Place at the TOP of a result screen, before
/// the original text/summary, so the user knows how much to trust the answer
/// before reading it. Deliberately never uses `AppColors.error` — that is
/// reserved for [AppRiskBadge]'s risk color family, so "I'm not sure I read
/// this right" is never visually confused with "this content is dangerous".
class AppConfidenceIndicator extends StatelessWidget {
  const AppConfidenceIndicator({
    super.key,
    required this.level,
    this.showPercentage = false,
    this.showStars = false,
  });

  final ReliabilityLevel level;
  final bool showPercentage;

  /// ui-prototype `.rsl-stars`(5칸 중 채워진 별) — [showPercentage]와 함께
  /// 쓸 때만 의미가 있다. 기존 호출부(Guardian 등)는 기본값 false라 영향
  /// 없다.
  final bool showStars;

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

    if (!showPercentage) {
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '답변 신뢰도 ${level.displayPercent}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showStars) ...[
                const SizedBox(height: AppSpacing.xs),
                _StarRow(filled: level.displayPercent ~/ 20),
              ],
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < filled ? Icons.star : Icons.star_border,
            size: 16,
            color: AppColors.warning,
          ),
      ],
    );
  }
}
