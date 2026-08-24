import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// One row in the Senior "기록" list — mirrors Guardian's own
/// `AnalysisRecordCard` (same table, same entity shape; kept as a separate
/// per-app widget since Senior/Guardian never cross-import `lib/` code).
/// 필드 순서는 Phase 44에서 PHASE 40 프로토타입의 `recordCard()`를 그대로
/// 따르도록 맞췄다 — 날짜(좌상단)+위험도(우상단) → 제목(타입) → 요약
/// 한 줄. 신뢰도는 카드에서는 보여주지 않는다(prototype과 동일 — 상세
/// 화면의 "상세정보"에서 확인).
class AnalysisRecordCard extends StatelessWidget {
  const AnalysisRecordCard({super.key, required this.result, this.onTap});

  final AnalysisResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final risk = result.riskLevel;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(result.createdAt),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (risk != null)
                AppRiskBadge(level: risk, label: riskLabel(l10n, risk)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.type == AnalysisType.document
                ? l10n.analysisTypeDocumentLabel
                : l10n.analysisTypeMessageLabel,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

/// Localized [AppRiskBadge] label for a [RiskLevel] — shared by every
/// `AppRiskBadge` call site in this app so the wording stays in one place.
String riskLabel(AppLocalizations l10n, RiskLevel level) => switch (level) {
  RiskLevel.safe => l10n.riskSafeLabel,
  RiskLevel.caution => l10n.riskCautionLabel,
  RiskLevel.dangerous => l10n.riskDangerousLabel,
};
