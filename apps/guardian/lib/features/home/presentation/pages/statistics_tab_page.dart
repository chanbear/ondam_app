import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/domain/analysis_stats.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart'
    show structuredFieldLabel, structuredFieldValue;
import '../../../connection/presentation/providers/connected_elders_provider.dart';
import '../../../schedule/presentation/providers/schedules_notifier.dart';

/// [AppFeeStatisticsSection]은 앱 무관 공용 위젯이라 자체 `AppLocalizations`가
/// 없다 — 이 앱의 l10n에서 라벨 번들을 만들어 전달한다(Statistics/Records
/// Localization Round).
AppFeeStatisticsLabels _feeStatisticsLabels(AppLocalizations l10n) {
  String monthLabel(DateTime date) => l10n.monthNumberLabel(date.month);
  String yearLabel(DateTime date) => l10n.yearNumberLabel(date.year);
  return AppFeeStatisticsLabels(
    emptyMessage: l10n.feeStatisticsEmptyMessage,
    totalFeeLabel: l10n.totalFeeLabel,
    averageFeeLabel: l10n.averageFeeLabel,
    maxFeeLabel: l10n.maxFeeLabel,
    recordCountLabel: l10n.feeRecordCountLabel,
    monthlyToggleLabel: l10n.monthlyToggleLabel,
    yearlyToggleLabel: l10n.yearlyToggleLabel,
    toggleSemanticSuffix: (label) => l10n.toggleViewSemanticLabel(label),
    monthlyTrendTitle: l10n.monthlyTrendTitle,
    yearlyTrendTitle: l10n.yearlyTrendTitle,
    noDataInPeriodMessage: l10n.noDataInPeriodMessage,
    footnote: l10n.feeFootnote,
    chartEmptyMessage: l10n.feeChartEmptyMessage,
    chartSemanticNoDataLabel: l10n.feeChartSemanticNoData,
    chartSemanticSummaryBuilder: (summary) =>
        l10n.feeChartSemanticSummary(summary),
    monthLabelBuilder: monthLabel,
    yearLabelBuilder: yearLabel,
    countLabelBuilder: (count) => l10n.countUnitLabel(count),
  );
}

/// 통계 탭. 원래 차트 라이브러리를 선택하지 않고(ui-component-spec.md
/// Decision 3) 고지서 구조화 필드도 원본 나열만 했던 이유는
/// `technical-decisions.md` OPEN QUESTIONS #12(고지서 통계 최종 데이터
/// 항목)가 미결정이었기 때문이다 — PHASE 37에서 `billingAmountKrw`/
/// `billingDate` 전용 필드가 실제로 연결되면서 그 결정이 내려졌다
/// (`FeeStatisticsSection`, `fl_chart` 도입). 개수 기반 [AnalysisStats]와
/// 고지서 원본 나열 섹션은 그대로 유지하고, 요금 통계는 그 사이에 별도
/// 섹션으로 추가한다.
class StatisticsTabPage extends ConsumerWidget {
  const StatisticsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final elders = ref.watch(connectedEldersProvider);
    final recordsState = ref.watch(analysisRecordsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: AppSectionHeader(title: l10n.navStatistics),
        ),
        if (elders.isNotEmpty)
          AppElderSwitcher(
            elders: elders,
            selectedElderId: ref.watch(effectiveSelectedElderIdProvider),
            onSelect: (elderId) =>
                ref.read(selectedElderIdProvider.notifier).select(elderId),
          ),
        Expanded(
          child: elders.isEmpty
              ? AppEmptyState(message: l10n.noConnectedEldersMessage)
              : recordsState.when(
                  loading: () => const AppLoading(),
                  error: (error, _) => AppError(
                    message: l10n.statisticsLoadError,
                    onRetry: () => ref.invalidate(analysisRecordsProvider),
                  ),
                  data: (records) => _StatisticsContent(
                    records: records,
                    schedulesState: ref.watch(schedulesProvider),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({
    required this.records,
    required this.schedulesState,
  });

  final List<AnalysisResult> records;
  final AsyncValue<List<Schedule>> schedulesState;

  String _trendSentence(AppLocalizations l10n, int delta) {
    if (delta == 0) return l10n.trendSameAsLastMonth;
    return delta > 0
        ? l10n.trendIncreasedLabel(delta)
        : l10n.trendDecreasedLabel(-delta);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (records.isEmpty) {
      return AppEmptyState(message: l10n.statisticsEmptyMessage);
    }

    final stats = AnalysisStats.compute(records, DateTime.now());
    final schedules = schedulesState.value ?? const <Schedule>[];
    final completedCount = schedules.where((s) => s.completed).length;
    final pendingCount = schedules.where((s) => !s.completed).length;

    final billRecords = records
        .where(
          (r) => r.structuredFields != null && r.structuredFields!.isNotEmpty,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: l10n.thisMonthCountLabel,
                value: l10n.countUnitLabel(stats.thisMonthCount),
                trend: _trendSentence(l10n, stats.trendDelta),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: l10n.riskyThisMonthCountLabel,
                value: l10n.countUnitLabel(stats.riskyThisMonthCount),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: l10n.completedScheduleCountLabel,
                value: l10n.countUnitLabel(completedCount),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: l10n.pendingScheduleCountLabel,
                value: l10n.countUnitLabel(pendingCount),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.recentWeeksActivityTitle),
        Text(
          l10n.recentWeeksActivitySubtitle,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _WeeklyActivityChart(records: records),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.guardianSummaryTitle),
        const SizedBox(height: AppSpacing.sm),
        _GuardianSummaryCard(
          riskyCount: stats.riskyThisMonthCount,
          pendingScheduleCount: pendingCount,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.feeStatisticsSectionTitle),
        const SizedBox(height: AppSpacing.sm),
        AppFeeStatisticsSection(
          records: records,
          labels: _feeStatisticsLabels(l10n),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.billingInfoSectionTitle),
        Text(
          l10n.billingInfoUndecidedNotice,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (billRecords.isEmpty)
          AppEmptyState(message: l10n.billingInfoEmptyMessage)
        else
          for (final record in billRecords)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(record.createdAt),
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final entry in record.structuredFields!.entries)
                      AppInfoRow(
                        label: structuredFieldLabel(l10n, entry.key),
                        value: structuredFieldValue(
                          l10n,
                          entry.key,
                          entry.value,
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}

/// 최근 4주(이번 주 포함) 분석 건수 — 이미 불러온 [records]에서 직접 세는
/// 순수 집계다(새 API 호출 없음). 별도 차트 라이브러리를 쓰지 않고 막대
/// 4개만 그린다 — 이 정도 데이터에 `fl_chart`를 새로 끌어오는 건 과하다.
class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({required this.records});

  final List<AnalysisResult> records;

  List<int> _weeklyCounts() {
    final now = DateTime.now();
    final counts = List<int>.filled(4, 0);
    for (final record in records) {
      final daysAgo = now.difference(record.createdAt).inDays;
      if (daysAgo < 0 || daysAgo >= 28) continue;
      final weekIndex = 3 - (daysAgo ~/ 7);
      counts[weekIndex]++;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = _weeklyCounts();
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);

    return AppCard(
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < counts.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${counts[i]}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: maxCount == 0
                          ? 6
                          : 6 + (counts[i] / maxCount) * 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      i == 0
                          ? l10n.fourWeeksAgoLabel
                          : i == counts.length - 1
                          ? l10n.thisWeekLabel
                          : '',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 참고 디자인(ui-prototype `stats-home`)의 "보호자 안심 요약" 체크리스트.
/// 원본은 3줄(위험 건/남은 일정/며칠째 확인)이지만 세 번째 줄("부모님 안전
/// 지표를 N일째 확인했습니다")은 이 앱이 추적하지 않는 값(연속 확인
/// 일수)이라 지어내지 않고 뺀다 — 실제로 갖고 있는 위험 건수/남은 일정만
/// 보여준다(`ui-design.md`/정직성 원칙). 둘 다 0이면 안심 문구 하나로
/// 대체한다.
class _GuardianSummaryCard extends StatelessWidget {
  const _GuardianSummaryCard({
    required this.riskyCount,
    required this.pendingScheduleCount,
  });

  final int riskyCount;
  final int pendingScheduleCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = [
      if (riskyCount > 0) l10n.guardianSummaryRiskyCount(riskyCount),
      if (pendingScheduleCount > 0)
        l10n.guardianSummaryPendingSchedule(pendingScheduleCount),
    ];
    if (lines.isEmpty) lines.add(l10n.guardianSummaryAllClear);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, line) in lines.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(line, style: AppTextStyles.bodyMedium)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
