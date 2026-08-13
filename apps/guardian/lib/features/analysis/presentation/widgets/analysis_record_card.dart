import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

/// One row in the "기록" list — date/type/summary + reliability + (message
/// type만) risk badge. Tapping opens [AnalysisRecordDetailView].
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
            _formatDate(result.createdAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}
