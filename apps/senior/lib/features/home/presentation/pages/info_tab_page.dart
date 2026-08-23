import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../info/domain/entities/benefit_service.dart';
import '../../../info/presentation/pages/benefit_service_detail_page.dart';
import '../../../info/presentation/providers/benefit_service_notifier.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// 정보 탭 — 나이/성별/지역 기반 맞춤 혜택 정보. 기존 온담앱은 나이만
/// 기준으로 카드 3개를 하드코딩했지만(콘텐츠가 고정돼 개인화 폭이
/// 제한적이었다), 이 구현은 `search-benefit-services` Edge Function을 통해
/// 실시간으로 검색하므로 사람마다(나이·성별·지역 조합) 결과가 달라진다.
class InfoTabPage extends ConsumerWidget {
  const InfoTabPage({super.key});

  void _openProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  void _openDetail(BuildContext context, BenefitService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BenefitServiceDetailPage(id: service.id, source: service.source),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(benefitServiceNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: AppSectionHeader(title: l10n.infoTabTitle),
        ),
        Expanded(
          child: resultsAsync.when(
            loading: () => const AppLoading(),
            error: (error, _) {
              if (error is ValidationFailure) {
                return AppEmptyState(
                  icon: Icons.person_outline,
                  message: error.message,
                  actionLabel: '내 정보 입력하기',
                  onAction: () => _openProfile(context),
                );
              }
              if (error is UnavailableFailure) {
                return AppEmptyState(
                  icon: Icons.info_outline,
                  message: error.message,
                );
              }
              final message = error is Failure
                  ? error.message
                  : '맞춤 혜택 정보를 불러오지 못했어요.';
              return AppError(
                message: message,
                onRetry: () => ref.invalidate(benefitServiceNotifierProvider),
              );
            },
            data: (results) {
              if (results == null || results.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.search_off,
                  message: '지금 조건에 맞는 혜택 정보를 찾지 못했어요.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                itemCount: results.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final service = results[index];
                  return AppCard(
                    onTap: () => _openDetail(context, service),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.title, style: AppTextStyles.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(service.summary, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
