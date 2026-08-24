import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/presentation/pages/region_input_page.dart';
import '../../domain/entities/senior_center.dart';
import '../providers/welfare_center_notifier.dart';

/// 경로당 찾기 — ONDAM 2.0 요구사항 30. 실제 데이터 소스가 아직 연결되지
/// 않아(§8) 검색은 항상 정직한 "아직 제공하지 않아요" 안내로 끝나지만,
/// 지역 확인 → 검색 → 목록 표시 흐름 자체는 실제 데이터 소스가 연결되는
/// 즉시 그대로 동작하도록 완성해 뒀다.
class WelfareCenterListPage extends ConsumerWidget {
  const WelfareCenterListPage({super.key});

  void _openRegionInput(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegionInputPage()));
  }

  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    final launched = await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.phoneLaunchError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final regionAsync = ref.watch(regionProvider);

    return AppScaffold(
      title: l10n.welfareCenterTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: regionAsync.when(
        loading: () => const AppLoading(),
        error: (_, _) => AppError(
          message: l10n.welfareCenterRegionLoadError,
          onRetry: () => ref.invalidate(regionProvider),
        ),
        data: (region) {
          if (region == null) {
            return AppEmptyState(
              icon: Icons.place_outlined,
              message: l10n.welfareCenterEmptyRegionMessage,
              actionLabel: l10n.enterRegionAction,
              onAction: () => _openRegionInput(context),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.myRegionTitle, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppInfoRow(label: region.displayName),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.searchNearbyButton,
                size: AppButtonSize.large,
                onPressed: () =>
                    ref.read(welfareCenterNotifierProvider.notifier).search(),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SearchResults(onCall: (phone) => _callPhone(context, phone)),
            ],
          );
        },
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.onCall});

  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(welfareCenterNotifierProvider);

    return resultsAsync.when(
      loading: () => const AppLoading(),
      error: (error, _) {
        if (error is UnavailableFailure) {
          return AppEmptyState(
            icon: Icons.info_outline,
            message: error.message,
          );
        }
        final message = error is Failure
            ? error.message
            : l10n.welfareCenterSearchError;
        return AppError(
          message: message,
          onRetry: () =>
              ref.read(welfareCenterNotifierProvider.notifier).search(),
        );
      },
      data: (results) {
        if (results == null) return const SizedBox.shrink();
        if (results.isEmpty) {
          return AppEmptyState(
            icon: Icons.search_off,
            message: l10n.welfareCenterNoResults,
          );
        }
        return Column(
          children: [
            for (final center in results) ...[
              _SeniorCenterCard(center: center, onCall: onCall),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _SeniorCenterCard extends StatelessWidget {
  const _SeniorCenterCard({required this.center, required this.onCall});

  final SeniorCenter center;
  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context) {
    final phone = center.phoneNumber;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(center.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(center.address, style: AppTextStyles.bodyMedium),
                if (center.distanceMeters != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${(center.distanceMeters! / 1000).toStringAsFixed(1)}km',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (phone != null)
            IconButton(
              iconSize: 32,
              tooltip: AppLocalizations.of(context)!.callButtonTooltip,
              icon: const Icon(Icons.call, color: AppColors.primary),
              onPressed: () => onCall(phone),
            ),
        ],
      ),
    );
  }
}
