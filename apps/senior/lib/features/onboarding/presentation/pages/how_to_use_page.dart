import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/voice_guide/voice_guide_scaffold.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 사용 방법 안내 — "더보기" 메뉴에서 언제든 다시 볼 수 있는 실제 기능
/// 튜토리얼. 이전에는 계정 설정용 [OnboardingFlowPage](최초 1회, 이름/
/// 성별/나이/지역 입력 + 보호자 QR 발급)를 그대로 재사용했는데, 이미 쓰고
/// 있는 사용자에게 "정보를 다시 입력하라"는 화면을 보여주는 게 말이 안 돼
/// 별도 화면으로 분리했다. 여기는 순수 안내용 — 아무 값도 저장하지 않는다.
class HowToUsePage extends StatefulWidget {
  const HowToUsePage({super.key});

  @override
  State<HowToUsePage> createState() => _HowToUsePageState();
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

// 실제 홈 화면(home_tab_page.dart)에 있는 기능만 소개한다 — 없는 기능을
// 지어내지 않는다.
const _stepCount = 7;

List<_TutorialStep> _steps(AppLocalizations l10n) => [
  _TutorialStep(
    icon: Icons.document_scanner_outlined,
    title: l10n.howToUseDocumentTitle,
    description: l10n.howToUseDocumentDesc,
  ),
  _TutorialStep(
    icon: Icons.sms_outlined,
    title: l10n.howToUseMessageTitle,
    description: l10n.howToUseMessageDesc,
  ),
  _TutorialStep(
    icon: Icons.mic,
    title: l10n.howToUseVoiceTitle,
    description: l10n.howToUseVoiceDesc,
  ),
  _TutorialStep(
    icon: Icons.phone_in_talk,
    title: l10n.howToUseEmergencyTitle,
    description: l10n.howToUseEmergencyDesc,
  ),
  _TutorialStep(
    icon: Icons.card_giftcard,
    title: l10n.howToUseBenefitTitle,
    description: l10n.howToUseBenefitDesc,
  ),
  _TutorialStep(
    icon: Icons.place_outlined,
    title: l10n.howToUseFacilityTitle,
    description: l10n.howToUseFacilityDesc,
  ),
  _TutorialStep(
    icon: Icons.history,
    title: l10n.howToUseRecordsTitle,
    description: l10n.howToUseRecordsDesc,
  ),
];

class _HowToUsePageState extends State<HowToUsePage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _stepCount - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = _steps(l10n);
    final isLast = _page == _stepCount - 1;
    return VoiceGuideScaffold(
      title: l10n.howToUseTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: false,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (page) => setState(() => _page = page),
              children: [for (final step in steps) _StepView(step: step)],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                if (_page > 0) ...[
                  Expanded(
                    child: AppButton(
                      label: l10n.previousButton,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.large,
                      onPressed: _previous,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: AppButton(
                    label: isLast ? l10n.confirmButton : l10n.nextButton,
                    size: AppButtonSize.large,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primarySoft,
            child: Icon(step.icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            step.title,
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
