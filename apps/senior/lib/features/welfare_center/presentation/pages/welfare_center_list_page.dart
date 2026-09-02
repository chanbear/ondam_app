import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/voice_guide/voice_guide_scaffold.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/l10n/failure_l10n.dart';
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

  // 2026-08-28 — Easy 모드 경로당 상세(ui-prototype `easy.welfare-detail`)에
  // "전화하기"뿐 아니라 "길 찾기"도 추가해달라는 사용자 요청 — 새 패키지 없이
  // 이미 있는 url_launcher로 지도 검색 URL을 연다.
  // 2026-08-29 — ui-prototype `senior.welfare-detail`이 쓰는 카카오맵 검색
  // 링크 형식(`map.kakao.com/link/search/{name} {address}`)과 맞춤.
  Future<void> _openDirections(BuildContext context, String query) async {
    final uri = Uri.parse(
      'https://map.kakao.com/link/search/${Uri.encodeComponent(query)}',
    );
    final launched = await launchUrl(uri);
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
    final easyMode = ref.watch(easyModeProvider);

    return VoiceGuideScaffold(
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
              _SearchResults(
                regionDisplayName: region.displayName,
                easyMode: easyMode,
                onCall: (phone) => _callPhone(context, phone),
                onDirections: (address) => _openDirections(context, address),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.regionDisplayName,
    required this.easyMode,
    required this.onCall,
    required this.onDirections,
  });

  final String regionDisplayName;
  final bool easyMode;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onDirections;

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
            message: localizeFailureMessage(context, error.message),
          );
        }
        final message = error is Failure
            ? localizeFailureMessage(context, error.message)
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ui-prototype `S("welfare-search")` — 결과 개수 요약 줄.
            Text(
              l10n.welfareCenterResultsSummary(
                regionDisplayName,
                results.length,
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final center in results) ...[
              _SeniorCenterCard(
                center: center,
                easyMode: easyMode,
                onCall: onCall,
                onDirections: onDirections,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _SeniorCenterCard extends StatelessWidget {
  const _SeniorCenterCard({
    required this.center,
    required this.easyMode,
    required this.onCall,
    required this.onDirections,
  });

  final SeniorCenter center;
  final bool easyMode;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onDirections;

  @override
  Widget build(BuildContext context) {
    final phone = center.phoneNumber;
    final l10n = AppLocalizations.of(context)!;
    // 2026-08-31 — ui-prototype `.welfare-list-cards`(사용자 요청)와 맞춰
    // 흰 `AppCard` 대신 위치 배지와 같은 계열 톤(`AppColors.successSoft`)의
    // 색 카드로 바꾼다. `AppCard`는 여러 화면이 공유하는 흰 배경 카드라 이
    // 화면만 바꾸려고 그 위젯 자체를 고치지 않는다(sms_message_tile.dart와
    // 동일한 이유/패턴).
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ui-prototype `S("welfare-search")` — 결과 카드 왼쪽 위치
              // 아이콘 배지(`T.iconBadgeTint("place","secondary","sm")`).
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.place, color: AppColors.surface, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.name,
                      style: easyMode
                          ? AppTextStyles.headlineMedium
                          : AppTextStyles.titleMedium,
                    ),
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
              // ui-prototype `S("welfare-detail")`(2026-08-29 — Easy의
              // 길찾기 버튼을 Senior에도 이식) — Easy 모드가 아닐 때도 전화
              // 걸기 옆에 길 찾기 아이콘 버튼을 함께 보여준다.
              if (!easyMode) ...[
                if (phone != null)
                  IconButton(
                    iconSize: AppSpacing.xl,
                    tooltip: l10n.callButtonTooltip,
                    icon: const Icon(Icons.call, color: AppColors.primary),
                    onPressed: () => onCall(phone),
                  ),
                IconButton(
                  iconSize: AppSpacing.xl,
                  tooltip: l10n.directionsButtonLabel,
                  icon: const Icon(Icons.directions, color: AppColors.primary),
                  onPressed: () =>
                      onDirections('${center.name} ${center.address}'),
                ),
              ],
            ],
          ),
          // 2026-08-28 — 사용자 요청: "경로당 상세에 전화하기 길찾기 두 개
          // 버튼" (ui-prototype `easy.welfare-detail` 참고). Easy 모드에서만
          // 전체너비 큰 버튼 2개로 노출한다.
          if (easyMode) ...[
            const SizedBox(height: AppSpacing.md),
            if (phone != null)
              AppButton(
                label: l10n.callButtonTooltip,
                size: AppButtonSize.large,
                onPressed: () => onCall(phone),
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.directionsButtonLabel,
              size: AppButtonSize.large,
              variant: AppButtonVariant.secondary,
              onPressed: () => onDirections('${center.name} ${center.address}'),
            ),
          ],
        ],
      ),
    );
    return card;
  }
}
