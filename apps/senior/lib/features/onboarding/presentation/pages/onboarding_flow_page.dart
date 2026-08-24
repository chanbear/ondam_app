import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/onboarding_status_provider.dart';
import '../widgets/accessibility_settings_form.dart';

/// 온보딩: 접근성 설정 → 내 정보(UI만, 저장 안 됨 — `profile` feature 백엔드
/// 없음) → 보호자 등록 안내(UI만 — 실제 연결 요청은 Phase 5 `connection`
/// feature) → 완료. `user-flow.md`의 기존 3단계 순서를 유지하되, 2·3단계는
/// 저장할 곳이 없다는 것을 화면에도 정직하게 표시한다(Mock 데이터로 있는
/// 척하지 않는다 — feature-spec.md REMOVE-1과 같은 원칙).
class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

enum _Step { accessibility, profile, guardian }

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  _Step _step = _Step.accessibility;

  void _next() {
    setState(() {
      _step = switch (_step) {
        _Step.accessibility => _Step.profile,
        _Step.profile => _Step.guardian,
        _Step.guardian => _Step.guardian,
      };
    });
  }

  Future<void> _finish() async {
    await ref.read(onboardingStatusProvider.notifier).markCompleted();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: switch (_step) {
        _Step.accessibility => l10n.accessibilitySettingsTitle,
        _Step.profile => l10n.profileTitle,
        _Step.guardian => l10n.guardianRegisterTitle,
      },
      scrollable: true,
      body: switch (_step) {
        _Step.accessibility => _AccessibilityStep(onNext: _next),
        _Step.profile => _ProfileStep(onNext: _next),
        _Step.guardian => _GuardianStep(onFinish: _finish),
      },
    );
  }
}

class _AccessibilityStep extends StatelessWidget {
  const _AccessibilityStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboardingAccessibilityIntro, style: AppTextStyles.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        const AccessibilitySettingsForm(),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: l10n.nextButton,
          size: AppButtonSize.large,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _ProfileStep extends StatefulWidget {
  const _ProfileStep({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _regionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboardingProfileIntro, style: AppTextStyles.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: l10n.nameLabel, controller: _nameController),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: l10n.ageLabel,
          controller: _ageController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: l10n.regionLabel, controller: _regionController),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: l10n.nextButton,
          size: AppButtonSize.large,
          onPressed: widget.onNext,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: widget.onNext, child: Text(l10n.skipButton)),
      ],
    );
  }
}

class _GuardianStep extends StatelessWidget {
  const _GuardianStep({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.guardianConnectComingSoonMessage,
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: l10n.saveAndStartButton,
          size: AppButtonSize.large,
          onPressed: onFinish,
        ),
      ],
    );
  }
}
