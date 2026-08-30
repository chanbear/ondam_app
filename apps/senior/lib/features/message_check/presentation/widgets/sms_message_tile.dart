import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/sms_message.dart';

/// One row in the recent-SMS list — 보낸 사람 → 내용 일부 → 날짜/시간 우선순위
/// (Phase 45-B §5, HTML prototype `messageList()`의 sender+date 상단 행과
/// 동일한 구조). `AppCard`가 이미 전체 너비 탭 영역을 제공한다.
class SmsMessageTile extends StatelessWidget {
  const SmsMessageTile({super.key, required this.message, this.onTap});

  final SmsMessage message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bodyPreview = message.body.trim();
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.sender ??
                            AppLocalizations.of(context)!.unknownSenderLabel,
                        style: AppTextStyles.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _formatDate(message.receivedAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  bodyPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
