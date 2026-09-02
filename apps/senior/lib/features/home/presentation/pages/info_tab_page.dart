import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/l10n/failure_l10n.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../info/domain/entities/benefit_service.dart';
import '../../../info/presentation/pages/benefit_service_detail_page.dart';
import '../../../info/presentation/providers/benefit_service_notifier.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

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
    final easyMode = ref.watch(easyModeProvider);
    final name = ref.watch(profileProvider).value?.name;

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
        // ui-prototype `S("info")` 상단 안내문 — 저장된 이름이 있을 때만
        // 보여준다(빈 값을 지어내지 않는다, home 인사말과 동일한 원칙).
        if (name != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.infoGreetingWithName(name),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Expanded(
          child: resultsAsync.when(
            loading: () => const AppLoading(),
            error: (error, _) {
              if (error is ValidationFailure) {
                return AppEmptyState(
                  icon: Icons.person_outline,
                  message: localizeFailureMessage(context, error.message),
                  actionLabel: l10n.enterMyInfoButton,
                  onAction: () => _openProfile(context),
                );
              }
              if (error is UnavailableFailure) {
                return AppEmptyState(
                  icon: Icons.info_outline,
                  message: localizeFailureMessage(context, error.message),
                );
              }
              final message = error is Failure
                  ? localizeFailureMessage(context, error.message)
                  : l10n.benefitLoadErrorMessage;
              return AppError(
                message: message,
                onRetry: () => ref.invalidate(benefitServiceNotifierProvider),
              );
            },
            data: (results) {
              if (results == null || results.isEmpty) {
                return AppEmptyState(
                  icon: Icons.search_off,
                  message: l10n.benefitNoResultsMessage,
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
                  // ui-prototype `S("info")` 카드는 좌측에 아이콘 배지를
                  // 둔다 — 실제 [BenefitService]는 항목별 아이콘/추천 사유
                  // 태그 데이터가 없어(prototype의 mock 전용 필드), 태그는
                  // 넣지 않고 아이콘만 공통 아이콘으로 맞춘다.
                  final card = AppCard(
                    onTap: () => _openDetail(context, service),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.smMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.title,
                                style: easyMode
                                    ? AppTextStyles.headlineMedium
                                    : AppTextStyles.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                service.summary,
                                style: AppTextStyles.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  return card;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
