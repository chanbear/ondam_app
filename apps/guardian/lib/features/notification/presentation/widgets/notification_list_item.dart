import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../domain/entities/notification_item.dart';

/// One row of the "실시간 알림" list — the actual `notifications` table
/// event (technical-decisions.md §1-4/§1-10), as opposed to
/// `AnalysisRecordCard` which renders an `analysis_results` row directly.
/// `type` is shown as-is (no hardcoded label set — same "제네릭 나열"
/// precedent as `AnalysisRecordDetailPage`'s `structuredFields`, since the
/// backend hasn't finalized `type` values yet).
class NotificationListItem extends StatelessWidget {
  const NotificationListItem({super.key, required this.item, this.onTap});

  final NotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!item.isRead)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.type, style: AppTextStyles.bodyLarge),
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
