import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';
import 'region_input_page.dart';

/// 내 정보 — 이름/나이(`profileProvider`)와 지역(`core/location`의 공유
/// `regionProvider`)을 함께 보여주고 저장한다(요구사항 31/32).
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

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

    final result = await ref
        .read(profileProvider.notifier)
        .save(name: _nameController.text, age: _ageController.text);
    if (!mounted) return;

    switch (result) {
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

    return AppScaffold(
      title: l10n.profileTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: l10n.nameLabel, controller: _nameController),
          const SizedBox(height: AppSpacing.md),
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
          AppCard(
            child: regionAsync.when(
              loading: () => const AppLoading(),
              error: (_, _) => Text(
                l10n.regionLoadError,
                style: AppTextStyles.bodyMedium,
              ),
              data: (region) => AppInfoRow(
                label: l10n.currentRegionLabel,
                value: region?.displayName ?? l10n.regionNotSetValue,
              ),
            ),
          ),
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
}
