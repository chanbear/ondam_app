import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// 고객 지원 — 아직 지원팀 연락처/티켓 시스템이 없어(회사 자체 고객센터
/// 정보가 이 저장소에 없음, Senior `support_page.dart`와 같은 이유) 실제
/// 연락 채널을 지어내지 않는다. 대신 실제로 자주 나올 질문(연결 방법/알림
/// 시점/다중 어르신/연결 해제)과, `technical-decisions.md` §2-4 화이트
/// 리스트에 실제로 정의된 개인정보 보호 범위만 안내한다.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = [
      (l10n.supportFaqConnectQuestion, l10n.supportFaqConnectAnswer),
      (l10n.supportFaqAlertQuestion, l10n.supportFaqAlertAnswer),
      (
        l10n.supportFaqMultipleEldersQuestion,
        l10n.supportFaqMultipleEldersAnswer,
      ),
      (l10n.supportFaqDisconnectQuestion, l10n.supportFaqDisconnectAnswer),
    ];

    return AppScaffold(
      title: l10n.supportTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: l10n.supportFaqSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (final (question, answer) in faqs)
                    ExpansionTile(
                      title: Text(question, style: AppTextStyles.bodyLarge),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            answer,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: l10n.supportPrivacySectionTitle),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.supportPrivacyNote,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
