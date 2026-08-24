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
                  data: (records) => _StatisticsContent(records: records),
                ),
        ),
      ],
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.records});

  final List<AnalysisResult> records;

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
