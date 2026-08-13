import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

/// "받은 연락" 상세 — 원문/요약/신뢰도/위험도/구조화 필드를 보여준다.
/// `structuredFields`는 key-value로 그대로 순회만 한다(고지서 항목 스키마는
/// 아직 OPEN QUESTIONS #12로 미확정 — 특정 키를 가정하지 않는다). Senior
/// 앱의 `document_scan`의 `AnalysisResultView`와 동일한 렌더링 원칙을
/// 따르되, 코드는 공유하지 않는다(architecture.md).
class AnalysisRecordDetailPage extends StatelessWidget {
  const AnalysisRecordDetailPage({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final risk = result.riskLevel;
    final structuredFields = result.structuredFields;
    final sourceExcerpt = result.sourceExcerpt;

    return AppScaffold(
      title: result.type == AnalysisType.document ? '문서 분석 상세' : '문자 확인 상세',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppConfidenceIndicator(level: result.reliability),
          const SizedBox(height: AppSpacing.lg),
          if (risk != null) ...[
            AppRiskBadge(level: risk),
            const SizedBox(height: AppSpacing.md),
          ],
          AppSectionHeader(title: '요약'),
          Text(result.summary, style: AppTextStyles.bodyLarge),
          if (sourceExcerpt != null && sourceExcerpt.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(title: '원문'),
            Text(sourceExcerpt, style: AppTextStyles.bodyMedium),
          ],
          if (structuredFields != null && structuredFields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(title: '구조화 정보'),
            for (final entry in structuredFields.entries)
              AppInfoRow(label: entry.key, value: '${entry.value}'),
          ],
        ],
      ),
    );
  }
}
