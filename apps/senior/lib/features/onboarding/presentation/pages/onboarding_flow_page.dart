import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

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
    return AppScaffold(
      title: switch (_step) {
        _Step.accessibility => '접근성 설정',
        _Step.profile => '내 정보',
        _Step.guardian => '보호자 등록',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('편하게 사용하실 수 있도록 먼저 설정할게요.', style: AppTextStyles.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        const AccessibilitySettingsForm(),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(label: '다음', size: AppButtonSize.large, onPressed: onNext),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알려주시면 더 도움이 되는 정보를 보여드릴 수 있어요. (선택 입력)',
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: '이름', controller: _nameController),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: '나이',
          controller: _ageController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: '지역', controller: _regionController),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: '다음',
          size: AppButtonSize.large,
          onPressed: widget.onNext,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: widget.onNext, child: const Text('건너뛰기')),
      ],
    );
  }
}

class _GuardianStep extends StatelessWidget {
  const _GuardianStep({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '보호자 연결은 곧 제공될 예정이에요. 준비되면 더보기 메뉴에서 언제든 연결하실 수 있어요.',
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: '저장하고 시작하기',
          size: AppButtonSize.large,
          onPressed: onFinish,
        ),
      ],
    );
  }
}
