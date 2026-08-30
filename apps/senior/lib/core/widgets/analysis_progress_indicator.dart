import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../l10n/generated/app_localizations.dart';
import 'analysis_progress_step.dart';

/// 문서/문자 분석 중 진행 상태를 보여준다(ONDAM 2.0 요구사항 12/21) —
/// document_scan/message_check 결과 화면이 공유한다. 단계 기반 표시값이며
/// 실제 AI의 정밀한 진행률이 아니다 — [AnalysisProgressStep] 참고.
class AnalysisProgressIndicator extends StatelessWidget {
  const AnalysisProgressIndicator({super.key, required this.step});

  final AnalysisProgressStep step;

  @override
  Widget build(BuildContext context) {
    final percent = step.percent;
    final l10n = AppLocalizations.of(context)!;
    final label = step.label(l10n);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Semantics(
        label: l10n.analysisProgressSemanticLabel(percent, label),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ui-prototype `doc-analyzing`/`msg-analyzing` — 퍼센트 숫자를
            // 진행바보다 먼저, primary 색으로 강조해 보여준다.
            ExcludeSemantics(
              child: Text(
                '$percent%',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 12,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ExcludeSemantics(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
