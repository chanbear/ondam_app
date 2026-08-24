import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/presentation/pages/region_input_page.dart';
import '../providers/local_gov_office_notifier.dart';
import 'privacy_info_page.dart';

/// 고객 지원 — 기존 온담앱의 "고객센터 연결/개인정보 보관 안내" 메뉴를
/// 반영한다. ONDAM 회사 자체의 고객센터 연락처는 이 저장소에 사업 정보가
/// 없어 만들 수 없다. 대신 어르신이 이미 등록한 지역(`regionProvider`)의
/// 관할 시청/군청/구청 또는 동 주민센터(행정복지센터) 실제 연락처를
/// 행정안전부 표준데이터로 안내한다 — `LocalGovOfficeNotifier` 참고. 이
/// 데이터 소스에는 전화번호 컬럼이 없어(`LocalGovOffice` 주석 참고)
/// 전화번호는 아직 항상 비어 있을 수 있다 — 가짜 번호를 만들지 않는다.
class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

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
      title: l10n.supportTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: '관할 행정기관 연락처'),
          const SizedBox(height: AppSpacing.sm),
          regionAsync.when(
            loading: () => const AppLoading(),
            error: (_, _) => AppError(
              message: '내 지역 정보를 불러오지 못했어요.',
              onRetry: () => ref.invalidate(regionProvider),
            ),
            data: (region) {
              if (region == null) {
                return AppEmptyState(
                  icon: Icons.place_outlined,
                  message: '관할 행정복지센터 연락처를 보려면 먼저 내 지역을 등록해주세요.',
                  actionLabel: l10n.enterRegionAction,
                  onAction: () => _openRegionInput(context),
                );
              }
              return _LocalGovOfficeCard(
                onCall: (phone) => _callPhone(context, phone),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: l10n.privacyInfoTitle),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PrivacyInfoPage())),
            child: Semantics(
              button: true,
              label: l10n.privacyInfoTitle,
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.privacyInfoDescription,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalGovOfficeCard extends ConsumerWidget {
  const _LocalGovOfficeCard({required this.onCall});

  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officeAsync = ref.watch(localGovOfficeNotifierProvider);

    return officeAsync.when(
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
            : '관할 행정복지센터 정보를 불러오지 못했어요.';
        return AppError(
          message: message,
          onRetry: () => ref.invalidate(localGovOfficeNotifierProvider),
        );
      },
      data: (office) {
        if (office == null) {
          return const AppEmptyState(
            icon: Icons.search_off,
            message: '내 지역의 행정복지센터 정보를 찾지 못했어요.',
          );
        }
        final phone = office.phoneNumber;
        return AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(office.address, style: AppTextStyles.bodyLarge),
                    if (phone == null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '전화번호 정보가 아직 없어요.',
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
      },
    );
  }
}
