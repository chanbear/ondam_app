import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/notification_item.dart';

/// One row of the "실시간 알림" list — the actual `notifications` table
/// event (technical-decisions.md §1-4/§1-10), as opposed to
/// `AnalysisRecordCard` which renders an `analysis_results` row directly.
///
/// `type` is currently always one of the 2 literal values the backend
/// writes (`risky_document`/`risky_message` — `supabase/functions/
/// analyze-document/index.ts`, `analyze-message/index.ts`), mapped to a
/// localized label below. Any other/future value falls back to the raw
/// string rather than guessing a new label (Notification Localization
/// Round — UI-layer label only, no new backend contract assumed).
///
/// Guardian UI Application Round 1 §8 — unread 상태는 색점 하나만으로
/// 표시하지 않는다(ui-design.md 접근성: "의미 전달이 색상에만 의존하지
/// 않게 한다"). prototype `notifCard()`의 `unread-chip`/`read-chip`과
/// 동일하게 텍스트 라벨을 함께 보여준다.
class NotificationListItem extends StatelessWidget {
  const NotificationListItem({super.key, required this.item, this.onTap});

  final NotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(l10n, item.type),
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatDateTime(item.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ReadStatusLabel(isRead: item.isRead),
        ],
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
    'risky_document' => l10n.notificationTypeRiskyDocument,
    'risky_message' => l10n.notificationTypeRiskyMessage,
    _ => type,
  };

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _ReadStatusLabel extends StatelessWidget {
  const _ReadStatusLabel({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            l10n.notificationUnreadLabel,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
          ),
        ],
      );
    }
    return Text(
      l10n.notificationReadLabel,
      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
    );
  }
}
