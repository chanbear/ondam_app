import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/demographics/presentation/providers/demographics_provider.dart';
import '../../../../core/easy_mode/easy_mode_outline_card.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/location/domain/entities/location_permission_status.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../../../../core/location/presentation/providers/location_di_providers.dart';
import '../../../../core/location/presentation/providers/location_permission_provider.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../connection/presentation/providers/connection_token_notifier.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
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

/// 온보딩: 접근성 설정 → 내 정보(이름/성별/나이/지역 실제 저장) → 보호자
/// QR 안내(실제 `connection` feature로 토큰 발급) → 설정 완료. 2026-08-31 —
/// 사용자 제공 레퍼런스 디자인에 맞춰 보호자 단계를 "곧 제공될 예정" 안내
/// 문구 대신 실제 QR 발급 화면으로, 마지막에 별도 완료 화면을 추가했다
/// (Mock 데이터로 있는 척하지 않는다 — feature-spec.md REMOVE-1과 같은
/// 원칙).
class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

enum _Step { accessibility, profile, guardianQr, complete }

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  _Step _step = _Step.accessibility;

  void _next() {
    setState(() {
      _step = switch (_step) {
        _Step.accessibility => _Step.profile,
        _Step.profile => _Step.guardianQr,
        _Step.guardianQr => _Step.complete,
        _Step.complete => _Step.complete,
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
    // "설정 완료!" 화면은 레퍼런스 이미지처럼 헤더 없는 전체화면이라
    // title을 주지 않는다(AppScaffold는 title이 null이면 헤더를 생략한다).
    final title = switch (_step) {
      _Step.accessibility => l10n.accessibilitySettingsTitle,
      _Step.profile => l10n.profileTitle,
      _Step.guardianQr => l10n.guardianRegisterTitle,
      _Step.complete => null,
    };
    return AppScaffold(
      // 스텝 전환 시 이전 스텝에서 스크롤한 위치가 새 스텝 콘텐츠에
      // 그대로 남아 상단이 잘려 보이는 문제 — AppScaffold(내부
      // SingleChildScrollView)가 키 없이 재사용되어 스크롤 offset이
      // 스텝 간에 유지되는 게 원인. 스텝별로 키를 줘서 스텝이 바뀔 때마다
      // 새 스크롤 위치(0)로 시작하게 한다.
      key: ValueKey(_step),
      title: title,
      // "설정 완료!" 화면은 짧은 고정 콘텐츠라 화면 전체 높이에서 수직
      // 가운데 정렬해야 레퍼런스와 맞는다 — SingleChildScrollView 안에서는
      // MainAxisAlignment.center가 아무 효과가 없어 이 화면만 스크롤을 끈다.
      scrollable: _step != _Step.complete,
      body: switch (_step) {
        _Step.accessibility => _AccessibilityStep(onNext: _next),
        _Step.profile => _ProfileStep(onNext: _next),
        _Step.guardianQr => _GuardianQrStep(onNext: _next),
        _Step.complete => _OnboardingCompleteStep(onFinish: _finish),
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

class _ProfileStep extends ConsumerStatefulWidget {
  const _ProfileStep({required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends ConsumerState<_ProfileStep> {
  final _nameController = TextEditingController();
  int _age = 60;
  Gender? _gender;

  // BUG: "내 지역 입력하기"가 별도 화면(RegionInputPage)으로 이동해버려
  // 온보딩 흐름이 끊겼다 — region_input_page.dart의 입력 UI/로직을 이
  // 스텝 안으로 그대로 이식한다(그 파일은 SupportPage/ProfilePage에서
  // 독립 화면으로 계속 쓰이므로 건드리지 않는다).
  String? _sido;
  final _sigunguController = TextEditingController();
  final _dongController = TextEditingController();
  bool _locating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedRegionFromSaved());
  }

  void _seedRegionFromSaved() {
    final saved = ref.read(regionProvider).value;
    if (saved == null || !mounted) return;
    setState(() {
      _sido = saved.sido;
      _sigunguController.text = saved.sigungu;
      _dongController.text = saved.dong;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sigunguController.dispose();
    _dongController.dispose();
    super.dispose();
  }

  Future<void> _pickSido() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _ProfileSidoPickerSheet(current: _sido),
    );
    if (selected == null || !mounted) return;
    setState(() => _sido = selected);
  }

  // region_input_page.dart `_useCurrentLocation`과 동일한 권한 확인 →
  // 현재 위치 조회 흐름.
  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    var status = ref.read(locationPermissionProvider).value;
    status ??= await ref
        .read(checkLocationPermissionUseCaseProvider)
        .call()
        .then(
          (result) => switch (result) {
            Ok(:final value) => value,
            Err() => null,
          },
        );

    if (status == LocationPermissionStatus.serviceDisabled) {
      unawaited(Geolocator.openLocationSettings().catchError((_) => false));
      setState(() {
        _locating = false;
        _locationError = AppLocalizations.of(
          context,
        )!.locationServiceDisabledError;
      });
      return;
    }
    if (status == LocationPermissionStatus.permanentlyDenied) {
      unawaited(Geolocator.openAppSettings().catchError((_) => false));
      setState(() {
        _locating = false;
        _locationError = AppLocalizations.of(
          context,
        )!.locationPermissionDeniedError;
      });
      return;
    }
    if (status == LocationPermissionStatus.denied || status == null) {
      await ref.read(locationPermissionProvider.notifier).request();
      status = ref.read(locationPermissionProvider).value;
    }
    if (status != LocationPermissionStatus.granted) {
      setState(() {
        _locating = false;
        _locationError = AppLocalizations.of(
          context,
        )!.locationPermissionRequiredError;
      });
      return;
    }

    final result = await ref.read(getCurrentRegionUseCaseProvider).call();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _sido = value.sido;
          _sigunguController.text = value.sigungu;
          _dongController.text = value.dong;
          _locating = false;
        });
      case Err(:final failure):
        setState(() {
          _locating = false;
          _locationError = failure.message;
        });
    }
  }

  // "선택 입력"이라 이름을 비워두고 넘어갈 수 있다 — 그때는 저장을 시도하지
  // 않는다(SaveProfileUseCase가 빈 이름을 항상 실패로 처리하므로, 시도하면
  // 매번 조용히 실패하는 요청만 쌓인다). 이름을 입력했을 때만 프로필/
  // 인구통계를 실제로 저장한 뒤 다음 단계로 넘어간다 — 지금까지는 이
  // 화면의 이름/성별/나이가 UI에만 남고 저장되지 않아 홈 인사말이 항상
  // 비어 있었다. 지역도 같은 원칙 — 시/도를 골랐을 때만 저장을 시도한다.
  Future<void> _handleNext() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ref.read(profileProvider.notifier).save(name: name, age: '$_age');
      final gender = _gender;
      if (gender != null) {
        await ref
            .read(demographicsProvider.notifier)
            .save(Demographics(age: _age, gender: gender));
      }
    }
    final sido = _sido;
    if (sido != null && sido.isNotEmpty) {
      await ref
          .read(regionProvider.notifier)
          .save(
            Region(
              sido: sido,
              sigungu: _sigunguController.text,
              dong: _dongController.text,
            ),
          );
    }
    if (!mounted) return;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    final sidoRow = Row(
      children: [
        Expanded(
          child: Text(
            _sido ?? l10n.sidoPlaceholder,
            style: AppTextStyles.bodyLarge,
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    );
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
              AppNumberStepper(
                label: l10n.ageLabel,
                value: _age,
                onChanged: (value) => setState(() => _age = value),
                decreaseSemanticLabel: l10n.ageDecreaseAction,
                increaseSemanticLabel: l10n.ageIncreaseAction,
                min: 1,
                max: 119,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.myRegionTitle,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // BUG: 여기서 RegionInputPage로 이동시켰던 걸 인라인 입력으로
              // 바꿨다 — region_input_page.dart의 시/도 선택 시트 +
              // 시/군/구·동 텍스트필드 + 현재 위치 자동 입력을 그대로 이식.
              easyMode
                  ? EasyOutlineCard(onTap: _pickSido, child: sidoRow)
                  : AppCard(onTap: _pickSido, child: sidoRow),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.sigunguLabel,
                controller: _sigunguController,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: l10n.dongLabel, controller: _dongController),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _locating
                    ? l10n.locatingButton
                    : l10n.useCurrentLocationButton,
                // "보호자 등록으로 넘어가기" primary 버튼과 색을 구분한다
                // (사용자 요청) — region_input_page.dart와 같은 패턴.
                variant: AppButtonVariant.secondary,
                isLoading: _locating,
                size: AppButtonSize.large,
                onPressed: _locating ? null : _useCurrentLocation,
              ),
              if (_locationError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _locationError!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: l10n.profileNextButton,
          size: AppButtonSize.large,
          onPressed: _handleNext,
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

/// `region_input_page.dart`의 `_SidoPickerSheet`와 같은 시각/동작 —
/// private 클래스라 파일 간 재사용이 안 돼(`_ProfileGenderOption`과 같은
/// 이유로) 그대로 복제한다.
class _ProfileSidoPickerSheet extends StatelessWidget {
  const _ProfileSidoPickerSheet({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            AppLocalizations.of(context)!.sidoPickerTitle,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final sido in koreaSidoList)
            ListTile(
              title: Text(sido, style: AppTextStyles.bodyLarge),
              trailing: sido == current
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(sido),
            ),
        ],
      ),
    );
  }
}

/// 보호자 등록 QR 안내 — 실제 `connection` feature(토큰 발급/실시간 만료)를
/// 그대로 쓴다. `ConnectionQrPage`(더보기 메뉴)와 같은 provider지만, 여기는
/// 재발급 대신 "다음"으로 온보딩을 이어간다는 점만 다르다 — 코드 중복이지만
/// 두 화면의 액션(재발급 vs 다음)이 달라 그대로 공유 위젯으로 뽑기보다는
/// 각자 화면에 맞게 둔다.
class _GuardianQrStep extends ConsumerWidget {
  const _GuardianQrStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokenState = ref.watch(connectionTokenProvider);
    return Column(
      children: [
        tokenState.when(
          loading: () => AppLoading(message: l10n.qrGeneratingMessage),
          error: (error, _) => AppError(
            message: l10n.qrGenerateError,
            onRetry: () =>
                ref.read(connectionTokenProvider.notifier).regenerate(),
          ),
          data: (token) => _QrDisplay(data: token.token),
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

class _QrDisplay extends ConsumerWidget {
  const _QrDisplay({required this.data});

  final String data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    final qrImage = QrImageView(
      data: data,
      size: 240,
      version: QrVersions.auto,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.qrShowGuardianPrompt,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        easyMode ? EasyOutlineCard(child: qrImage) : AppCard(child: qrImage),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.qrScanExplanation,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 설정 완료 화면 — 초록색 체크 서클 + 안내 문구 + "온담 시작하기".
class _OnboardingCompleteStep extends StatelessWidget {
  const _OnboardingCompleteStep({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _CompleteCheckMark(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.onboardingCompleteTitle,
          style: AppTextStyles.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.onboardingCompleteSubtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: l10n.splashStartButton,
          size: AppButtonSize.large,
          onPressed: onFinish,
        ),
      ],
    );
  }
}

class _CompleteCheckMark extends StatelessWidget {
  const _CompleteCheckMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: AppColors.surface, size: 48),
    );
  }
}

