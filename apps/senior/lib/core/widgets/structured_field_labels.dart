import '../../l10n/generated/app_localizations.dart';

/// `AnalysisResult.structuredFields`는 서버가 채운 raw key-value(예:
/// `riskType: "delivery_scam"`)라 그대로 화면에 보이면 안 된다. Guardian 앱
/// (`analysis_record_card.dart`)에 이미 있던 동일한 매핑을 Senior에도 그대로
/// 옮긴다 — `analysis_result_view.dart`/`easy_analysis_result_view.dart`가
/// 이 매핑 없이 raw 값을 직접 보여주고 있었다.
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
