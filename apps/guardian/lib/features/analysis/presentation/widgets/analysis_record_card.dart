import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// One row in the "기록" list — date/type/summary + reliability + (message
/// type만) risk badge. Tapping opens [AnalysisRecordDetailView].
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
                  result.type == AnalysisType.document
                      ? l10n.analysisTypeDocumentLabel
                      : l10n.analysisTypeMessageLabel,
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              if (risk != null)
                AppRiskBadge(level: risk, label: riskLabel(l10n, risk)),
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

/// Localized [AppRiskBadge] label for a [RiskLevel] — shared by every
/// `AppRiskBadge` call site in this app so the wording stays in one place.
String riskLabel(AppLocalizations l10n, RiskLevel level) => switch (level) {
  RiskLevel.safe => l10n.riskSafeLabel,
  RiskLevel.caution => l10n.riskCautionLabel,
  RiskLevel.dangerous => l10n.riskDangerousLabel,
};

/// `AnalysisResult.structuredFields` is a raw `Map<String, Object?>` the AI
/// fills in — most keys/values have no fixed shape, so they're shown as-is.
/// The one exception is `riskType` (from `analyze-message`'s fixed enum,
/// `supabase/functions/analyze-message/risk_classifier.ts`), whose raw
/// snake_case value (e.g. "delivery_scam") is worth humanizing since it's
/// always one of exactly 9 known values. Everything else passes through
/// unchanged — no new analysis logic, just a UI-layer label for one known key.
String structuredFieldLabel(AppLocalizations l10n, String key) =>
    key == 'riskType' ? l10n.structuredFieldRiskTypeLabel : key;

String structuredFieldValue(AppLocalizations l10n, String key, Object? value) {
  if (key == 'riskType') return riskTypeValueLabel(l10n, '$value');
  return '$value';
}

String riskTypeValueLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'voice_phishing_lure' => l10n.riskTypeVoicePhishingLure,
      'smishing' => l10n.riskTypeSmishing,
      'loan_scam' => l10n.riskTypeLoanScam,
      'impersonation_authority' => l10n.riskTypeImpersonationAuthority,
      'delivery_scam' => l10n.riskTypeDeliveryScam,
      'investment_scam' => l10n.riskTypeInvestmentScam,
      'romance_scam' => l10n.riskTypeRomanceScam,
      'other_scam' => l10n.riskTypeOtherScam,
      'none' => l10n.riskTypeNone,
      _ => value,
    };
