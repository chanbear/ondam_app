import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

/// One row in the Senior "기록" list — mirrors Guardian's own
/// `AnalysisRecordCard` (same table, same entity shape; kept as a separate
/// per-app widget since Senior/Guardian never cross-import `lib/` code).
/// Unlike Guardian's version, this also shows the time (Senior only ever
/// sees their own records, so date-only grouping across many elders isn't a
/// concern) and reliability, since PHASE 10 requires 위험도 + 신뢰도 both.
class AnalysisRecordCard extends StatelessWidget {
  const AnalysisRecordCard({super.key, required this.result, this.onTap});

  final AnalysisResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final risk = result.riskLevel;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.type == AnalysisType.document
                    ? Icons.description_outlined
                    : Icons.sms_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  result.type == AnalysisType.document ? '문서 분석' : '문자 확인',
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              if (risk != null) AppRiskBadge(level: risk),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatDateTime(result.createdAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppConfidenceIndicator(level: result.reliability),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
