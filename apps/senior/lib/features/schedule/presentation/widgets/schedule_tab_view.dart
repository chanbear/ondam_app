import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../pages/schedule_form_page.dart';
import '../providers/schedule_notifier.dart';
import 'schedule_list_item.dart';

/// 기록 탭의 "일정" 서브탭 본문 — `RecordsTabPage`가 `TabBarView`의 두 번째
/// 탭으로 이 위젯을 그대로 끼워 넣는다.
class ScheduleTabView extends ConsumerWidget {
  const ScheduleTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: AppButton(
            label: '일정 추가',
            icon: Icons.add,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScheduleFormPage())),
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const AppLoading(),
            error: (error, _) {
              final message = error is Failure
                  ? error.message
                  : '일정을 불러오지 못했어요.';
              return AppError(
                message: message,
                onRetry: () => ref.invalidate(scheduleListProvider),
              );
            },
            data: (schedules) {
              if (schedules.isEmpty) {
                return const AppEmptyState(message: '등록된 일정이 없어요.');
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(scheduleListProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: schedules.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return ScheduleListItem(
                      schedule: schedule,
                      onToggle: (completed) => ref
                          .read(scheduleListProvider.notifier)
                          .toggleCompleted(schedule.id, completed),
                      onDelete: () => _confirmDelete(context, ref, schedule),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '일정 삭제',
      message: '"${schedule.title}" 일정을 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(scheduleListProvider.notifier).delete(schedule.id);
  }
}
