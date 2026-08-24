import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

/// 일정 목록 한 줄 — 체크박스(완료 토글) + 제목 + 날짜/시간(+ 반복 표시) +
/// 삭제 버튼. `AppInfoRow`의 checklist 변형은 보조 줄(날짜/시간)을 지원하지
/// 않아 이 화면 전용으로 직접 구성한다.
class ScheduleListItem extends StatelessWidget {
  const ScheduleListItem({
    super.key,
    required this.schedule,
    required this.onToggle,
    required this.onDelete,
  });

  final Schedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: schedule.completed,
            onChanged: (value) => onToggle(value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      decoration: schedule.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: schedule.completed
                          ? AppColors.textSecondary
                          : null,
                    ),
                  ),
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
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            semanticLabel: '${schedule.title} 일정 삭제',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.month}월 ${dt.day}일 '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
