import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/sms_message.dart';
import 'message_risk_result_page.dart';

/// 선택한 문자의 원문 확인 — 분석 요청 전 사용자가 무엇을 분석하는지 한 번
/// 더 확인할 수 있게 한다("문자 선택 → 선택된 문자 확인 → 분석하기").
/// 구조(보낸 사람 → 발신 정보/날짜 → 문자 원문 → 분석하기)는 HTML
/// prototype `messageDetail()`을 그대로 따른다(Phase 45-B §6).
class SmsMessageDetailPage extends ConsumerWidget {
  const SmsMessageDetailPage({super.key, required this.message});

  final SmsMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(easyModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.messageCheckLabel,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.sender ?? l10n.unknownSenderLabel,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    Text(
                      _formatDateTime(message.receivedAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: AppSpacing.md),
                // 긴 문자도 읽기 편하도록 bodyLarge(줄 간격 1.5)를 그대로
                // 쓴다 — 문자 원문은 화면을 과밀하게 만들지 않도록 카드
                // padding만으로 여백을 확보한다(Phase 45-B §6).
                Text(message.body, style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.analyzeButton,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MessageRiskResultPage(message: message),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
