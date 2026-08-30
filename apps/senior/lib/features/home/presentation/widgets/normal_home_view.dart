import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../core/widgets/home_feature_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../schedule/presentation/providers/schedule_notifier.dart';

/// Normal Mode home content — 기능 목록(긴급 도움 포함) → 오늘의 일정
/// 미리보기. ui-prototype `S("home")`의 `feature-grid.cols-1`을 따라 2열
/// 아이콘 그리드가 아니라 아이콘+라벨+서브텍스트+chevron이 있는 전체너비
/// 행을 세로로 나열한다(2026-08-30 정렬). 오늘의 일정은 이미 기록 탭의
/// 일정 서브탭이 쓰는 [scheduleListProvider]를 그대로 읽기만 한다 — 새
/// 데이터소스를 만들지 않는다. 오늘 일정이 없거나 아직 로딩/에러 중이면
/// 섹션 자체를 숨긴다(빈 영역 노출 금지 원칙, ui-principles.md) — 홈 화면의
/// 부가 미리보기라 기록 탭과 달리 별도 로딩/에러 UI를 두지 않는다.
class NormalHomeView extends ConsumerWidget {
  const NormalHomeView({super.key, required this.features});

  final List<HomeFeatureItem> features;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todaySchedules =
        ref
            .watch(scheduleListProvider)
            .value
            ?.where(
              (s) =>
                  s.scheduledAt.year == now.year &&
                  s.scheduledAt.month == now.month &&
                  s.scheduledAt.day == now.day &&
                  !s.completed,
            )
            .take(2)
            .toList() ??
        const [];
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      children: [
        for (final item in features) ...[
          HomeFeatureLargeButton(item: item, subtitle: item.subtitle),
          const SizedBox(height: AppSpacing.md),
        ],
        if (todaySchedules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: l10n.todayScheduleTitle),
          for (final schedule in todaySchedules)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TodayScheduleRow(schedule: schedule),
            ),
        ],
      ],
    );
  }
}

/// 오늘의 일정 미리보기 행 — 시간 + 제목만 보여주는 읽기 전용 카드(체크/삭제
/// 같은 조작은 기록 탭의 [ScheduleListItem]에서만 한다). 탭하면 기록 탭으로
/// 이동(요구사항에 없는 별도 상세 화면을 새로 만들지 않는다).
class _TodayScheduleRow extends StatelessWidget {
  const _TodayScheduleRow({required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final time =
        '${schedule.scheduledAt.hour.toString().padLeft(2, '0')}:'
        '${schedule.scheduledAt.minute.toString().padLeft(2, '0')}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                time,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(schedule.title, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
