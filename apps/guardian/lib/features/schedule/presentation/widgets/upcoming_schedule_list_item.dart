import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

/// 홈 "다가오는 일정" 한 줄 — 읽기 전용(Guardian은 일정을 만들거나 고칠 수
/// 없다, feature-spec.md MODIFY-9). 제목 + 날짜/시간(+ 반복 표시)만
/// 보여준다.
class UpcomingScheduleListItem extends StatelessWidget {
  const UpcomingScheduleListItem({super.key, required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.event_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      _formatDateTime(schedule.scheduledAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (schedule.isRecurring) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.repeat,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        ' 매일 반복',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.month}월 ${dt.day}일 '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
