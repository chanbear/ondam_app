import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

/// Renders a completed [AnalysisResult] — reliability sentence, optional risk
/// badge, summary, and structured fields. Shared by `document_scan` (Phase 4)
/// and `message_check` (Phase 7): both features produce the same
/// [AnalysisResult] shape and must not each grow their own result renderer
/// (architecture.md "두 개 이상의 feature가 실제로 공유하는 위젯만
/// core/widgets에 둔다").
class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final risk = result.riskLevel;
    final structuredFields = result.structuredFields;

    return ListView(
      children: [
        AppConfidenceIndicator(level: result.reliability),
        const SizedBox(height: AppSpacing.lg),
        if (risk != null) ...[
          AppRiskBadge(level: risk),
          const SizedBox(height: AppSpacing.md),
        ],
        AppSectionHeader(title: '요약'),
        Text(result.summary, style: AppTextStyles.bodyLarge),
        if (structuredFields != null && structuredFields.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: '문서 정보'),
          for (final entry in structuredFields.entries)
            AppInfoRow(label: entry.key, value: '${entry.value}'),
        ],
      ],
    );
  }
}
