import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/widgets/language_picker_tile.dart';
import '../providers/onboarding_status_provider.dart';
import '../widgets/accessibility_settings_form.dart';

/// Easy Mode에서 각 온보딩 스텝 콘텐츠에 여백을 준다. 이전에는 굵은 먹색
/// 테두리 카드로도 감쌌으나 그 시각 요소는 2026-08-29 ui-prototype에서
/// 삭제되어 지금은 padding만 남는다. 스텝 3개가 각자 다른
/// StatelessWidget/StatefulWidget이라 공통 wrapper로 뺀다 — 3곳에 같은
/// Container 코드를 반복하지 않기 위함(riverpod.md 범위 밖의 순수 UI
/// 헬퍼라 Provider로 만들지 않는다).
class _EasyModeCard extends ConsumerWidget {
  const _EasyModeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(easyModeProvider)) return child;
    return Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child);
  }
}

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
      // 스텝 전환 시 이전 스텝에서 스크롤한 위치가 새 스텝 콘텐츠에
      // 그대로 남아 상단이 잘려 보이는 문제 — AppScaffold(내부
      // SingleChildScrollView)가 키 없이 재사용되어 스크롤 offset이
      // 스텝 간에 유지되는 게 원인. 스텝별로 키를 줘서 스텝이 바뀔 때마다
      // 새 스크롤 위치(0)로 시작하게 한다.
      key: ValueKey(_step),
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
        Text(
          l10n.onboardingAccessibilityHeadline,
          style: AppTextStyles.displayLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.onboardingAccessibilityIntro,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _EasyModeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccessibilitySettingsForm(),
              const SizedBox(height: AppSpacing.xl),
              AppSectionHeader(title: l10n.settingsLanguage),
              const LanguagePickerTile(),
            ],
          ),
        ),
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
  Gender? _gender;

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
        _EasyModeCard(
          child: Column(
            children: [
              AppTextField(label: l10n.nameLabel, controller: _nameController),
              const SizedBox(height: AppSpacing.xxl),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.genderSectionLabel,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _ProfileGenderOption(
                      label: l10n.genderMaleLabel,
                      selected: _gender == Gender.male,
                      onTap: () => setState(() => _gender = Gender.male),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ProfileGenderOption(
                      label: l10n.genderFemaleLabel,
                      selected: _gender == Gender.female,
                      onTap: () => setState(() => _gender = Gender.female),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                label: l10n.ageLabel,
                controller: _ageController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.regionLabel,
                controller: _regionController,
              ),
            ],
          ),
        ),
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

/// `profile_page.dart`의 `_GenderOption`과 동일한 시각 패턴 — 재사용 범위가
/// 아직 이 두 화면뿐이라 core로 승격하지 않고 그대로 복제한다.
class _ProfileGenderOption extends StatelessWidget {
  const _ProfileGenderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
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
        _EasyModeCard(
          child: Text(
            l10n.guardianConnectComingSoonMessage,
            style: AppTextStyles.bodyLarge,
          ),
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
