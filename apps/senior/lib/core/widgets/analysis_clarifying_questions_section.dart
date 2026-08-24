import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../l10n/generated/app_localizations.dart';

/// ONDAM 2.0 결과 화면의 "궁금한 점이 있나요?" 영역 — AI가 준 후속 질문
/// ([questions], 있다면 나열) + 음성 비서 진입 버튼. 실제 음성 인식/응답
/// 로직은 여기서 구현하지 않는다(Phase 4 §10) — 기존 음성 비서 화면으로
/// 이동하는 진입점만 연결한다. 진입 버튼은 [questions]가 비어있어도
/// 항상 보여준다 — AI가 준 질문이 없는 것과 "더 물어볼 방법이 없는 것"은
/// 다르다.
class AnalysisClarifyingQuestionsSection extends StatelessWidget {
  const AnalysisClarifyingQuestionsSection({
    super.key,
    required this.questions,
    required this.onAskByVoice,
    this.buttonSize = AppButtonSize.standard,
  });

  final List<String>? questions;
  final VoidCallback onAskByVoice;
  final AppButtonSize buttonSize;

  @override
  Widget build(BuildContext context) {
    final list = questions;
    final hasQuestions = list != null && list.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.clarifyingQuestionsTitle),
        if (hasQuestions) ...[
          for (final question in list)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('· $question', style: AppTextStyles.bodyMedium),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton(
          label: l10n.askByVoiceButton,
          onPressed: onAskByVoice,
          size: buttonSize,
        ),
      ],
    );
  }
}
