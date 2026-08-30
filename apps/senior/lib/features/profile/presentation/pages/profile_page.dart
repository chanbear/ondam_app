import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/demographics/presentation/providers/demographics_provider.dart';
import '../../../../core/easy_mode/easy_mode_outline_card.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';
import 'region_input_page.dart';

/// 내 정보 — 이름/나이(`profileProvider`)와 지역(`core/location`의 공유
/// `regionProvider`)을 함께 보여주고 저장한다(요구사항 31/32). 성별은
/// ONDAM 2.0 "정보" 탭의 맞춤 혜택 정보 검색 조건으로 쓰이며,
/// `core/demographics`의 공유 `demographicsProvider`를 통해 나이와 함께
/// 저장된다 — l10n 키가 없는 신규 문구라 이 화면 전용 한글 문자열로
/// 둔다(기존 문구는 계속 l10n을 사용).
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  Gender? _gender;

  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final profileResult = await ref
        .read(profileProvider.notifier)
        .save(name: _nameController.text, age: _ageController.text);
    if (!mounted) return;

    if (profileResult case Err(:final failure)) {
      setState(() {
        _saving = false;
        _saveError = failure.message;
      });
      return;
    }

    // 성별을 아직 선택하지 않았으면 성별 저장은 시도하지 않는다 — 이름/
    // 나이만 입력한 기존 사용자 흐름을 그대로 유지한다.
    final gender = _gender;
    if (gender == null) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)),
      );
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    final demographicsResult = await ref
        .read(demographicsProvider.notifier)
        .save(Demographics(age: age, gender: gender));
    if (!mounted) return;

    switch (demographicsResult) {
      case Ok():
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)),
        );
      case Err(:final failure):
        setState(() {
          _saving = false;
          _saveError = failure.message;
        });
    }
  }

  void _openRegionInput() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegionInputPage()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    final regionAsync = ref.watch(regionProvider);
    final profileAsync = ref.watch(profileProvider);
    ref.listen<AsyncValue<Profile?>>(profileProvider, (previous, next) {
      final profile = next.value;
      if (profile == null) return;
      // 사용자가 아직 아무것도 입력하지 않았을 때만 서버 값으로 채운다 —
      // 이미 타이핑 중인 값을 조회 결과로 덮어쓰지 않는다.
      if (_nameController.text.isEmpty && _ageController.text.isEmpty) {
        _nameController.text = profile.name;
        _ageController.text = profile.age.toString();
      }
    });
    ref.listen<AsyncValue<Demographics?>>(demographicsProvider, (
      previous,
      next,
    ) {
      final gender = next.value?.gender;
      // 사용자가 아직 아무것도 고르지 않았을 때만 서버 값으로 채운다 —
      // 이미 고른 선택을 조회 결과로 덮어쓰지 않는다.
      if (gender != null && _gender == null) {
        setState(() => _gender = gender);
      }
    });

    return AppScaffold(
      title: l10n.profileTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ui-prototype `senior.onboard-profile` 필드 순서(이름 → 성별 →
          // 나이 → 지역)와 맞춤.
          AppTextField(label: l10n.nameLabel, controller: _nameController),
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.genderSectionLabel, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _GenderOption(
                  label: l10n.genderMaleLabel,
                  selected: _gender == Gender.male,
                  onTap: () => setState(() => _gender = Gender.male),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GenderOption(
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
          if (profileAsync.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.profileLoadError,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.myRegionTitle, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _regionCard(easyMode: easyMode, l10n: l10n, regionAsync: regionAsync),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.enterRegionAction,
            size: AppButtonSize.large,
            onPressed: _openRegionInput,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: l10n.saveButton,
            isLoading: _saving,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: _saving ? null : _save,
          ),
          if (_saveError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _saveError!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  // 2026-08-28 — 쉬운 모드일 때만 `EasyOutlineCard`(굵은 먹색 테두리)로.
  Widget _regionCard({
    required bool easyMode,
    required AppLocalizations l10n,
    required AsyncValue<Region?> regionAsync,
  }) {
    final content = regionAsync.when(
      loading: () => const AppLoading(),
      error: (_, _) =>
          Text(l10n.regionLoadError, style: AppTextStyles.bodyMedium),
      data: (region) => AppInfoRow(
        label: l10n.currentRegionLabel,
        value: region?.displayName ?? l10n.regionNotSetValue,
      ),
    );
    return easyMode ? EasyOutlineCard(child: content) : AppCard(child: content);
  }
}

/// 성별 2지선다 — 디자인 시스템에 segmented control이 없어 이 화면
/// 전용으로 작은 토글 위젯을 둔다(`region_input_page.dart`의
/// `_SidoPickerSheet`와 동일하게, 재사용이 실제로 필요해지기 전까지는
/// feature-local로 둔다).
class _GenderOption extends StatelessWidget {
  const _GenderOption({
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
