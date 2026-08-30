import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_outline_card.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/location/domain/entities/location_permission_status.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../../../../core/location/presentation/providers/location_di_providers.dart';
import '../../../../core/location/presentation/providers/location_permission_provider.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "내 지역 입력하기" 전체 흐름 — ONDAM 2.0 요구사항 31/32. 시/도는 목록에서
/// 고르고(오타/난이도 문제 없이), 시/군/구·읍/면/동은 직접 입력하거나
/// "현재 위치로 자동 입력"으로 채운다. 저장 전 항상 값을 눈으로 확인하고
/// 고칠 수 있다 — 위치 인식 결과를 조용히 그대로 저장하지 않는다.
class RegionInputPage extends ConsumerStatefulWidget {
  const RegionInputPage({super.key});

  @override
  ConsumerState<RegionInputPage> createState() => _RegionInputPageState();
}

class _RegionInputPageState extends ConsumerState<RegionInputPage> {
  String? _sido;
  final _sigunguController = TextEditingController();
  final _dongController = TextEditingController();

  bool _locating = false;
  String? _locationError;

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromSaved());
  }

  @override
  void dispose() {
    _sigunguController.dispose();
    _dongController.dispose();
    super.dispose();
  }

  void _seedFromSaved() {
    final saved = ref.read(regionProvider).value;
    if (saved == null || !mounted) return;
    setState(() {
      _sido = saved.sido;
      _sigunguController.text = saved.sigungu;
      _dongController.text = saved.dong;
    });
  }

  Future<void> _pickSido() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _SidoPickerSheet(current: _sido),
    );
    if (selected == null || !mounted) return;
    setState(() => _sido = selected);
  }

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
      // 설정 화면으로 이동하는 동안 우리 UI가 멈춰 기다릴 이유는 없다 —
      // fire-and-forget으로 열고, 안내 문구는 곧장 보여준다. 플랫폼이 이
      // 호출을 지원하지 않아도(드문 예외) 안내 문구만으로 충분하다.
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

  Future<void> _save() async {
    final sido = _sido;
    if (sido == null || sido.isEmpty) {
      setState(
        () => _saveError = AppLocalizations.of(context)!.sidoRequiredError,
      );
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final region = Region(
      sido: sido,
      sigungu: _sigunguController.text,
      dong: _dongController.text,
    );
    final result = await ref.read(regionProvider.notifier).save(region);
    if (!mounted) return;

    switch (result) {
      case Ok():
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.regionSaved)),
        );
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _saving = false;
          _saveError = failure.message;
        });
    }
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
    return AppScaffold(
      title: l10n.enterRegionAction,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sidoLabel, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          // 2026-08-28 — 쉬운 모드일 때만 `EasyOutlineCard`(굵은 먹색 테두리)로.
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
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _locating
                ? l10n.locatingButton
                : l10n.useCurrentLocationButton,
            isLoading: _locating,
            size: AppButtonSize.large,
            onPressed: _locating ? null : _useCurrentLocation,
          ),
          if (_locationError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _locationError!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: l10n.saveButton,
            isLoading: _saving,
            size: AppButtonSize.large,
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

class _SidoPickerSheet extends StatelessWidget {
  const _SidoPickerSheet({required this.current});

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
