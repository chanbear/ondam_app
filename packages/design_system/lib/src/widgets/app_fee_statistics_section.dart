import 'package:flutter/material.dart';
import 'package:ondam_models/ondam_models.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import '../utils/krw_formatter.dart';
import 'app_card.dart';
import 'app_empty_state.dart';
import 'app_fee_trend_chart.dart';
import 'app_info_row.dart';
import 'app_stat_card.dart';

enum _FeePeriodView { monthly, yearly }

/// User-facing strings for [AppFeeStatisticsSection] — passed in by the
/// caller (each app's own `AppLocalizations`) rather than hardcoded here,
/// since this widget has no `AppLocalizations` of its own (Senior/Guardian
/// each generate a separate one).
class AppFeeStatisticsLabels {
  const AppFeeStatisticsLabels({
    required this.emptyMessage,
    required this.totalFeeLabel,
    required this.averageFeeLabel,
    required this.maxFeeLabel,
    required this.recordCountLabel,
    required this.monthlyToggleLabel,
    required this.yearlyToggleLabel,
    required this.toggleSemanticSuffix,
    required this.monthlyTrendTitle,
    required this.yearlyTrendTitle,
    required this.noDataInPeriodMessage,
    required this.footnote,
    required this.chartEmptyMessage,
    required this.chartSemanticNoDataLabel,
    required this.chartSemanticSummaryBuilder,
    required this.monthLabelBuilder,
    required this.yearLabelBuilder,
    required this.countLabelBuilder,
  });

  final String emptyMessage;
  final String totalFeeLabel;
  final String averageFeeLabel;
  final String maxFeeLabel;
  final String recordCountLabel;
  final String monthlyToggleLabel;
  final String yearlyToggleLabel;

  /// e.g. "{label} 보기" — appended after the toggle label for screen
  /// readers ("월별 보기"/"연별 보기").
  final String Function(String label) toggleSemanticSuffix;

  final String monthlyTrendTitle;
  final String yearlyTrendTitle;
  final String noDataInPeriodMessage;
  final String footnote;

  final String chartEmptyMessage;
  final String chartSemanticNoDataLabel;
  final String Function(String pointsSummary) chartSemanticSummaryBuilder;

  /// x축 라벨 (예: ko "1월", en "Jan").
  final String Function(DateTime month) monthLabelBuilder;

  /// x축 라벨 (예: ko "2026년", en "2026").
  final String Function(DateTime year) yearLabelBuilder;

  /// e.g. ko "{count}건", en "{count} records".
  final String Function(int count) countLabelBuilder;
}

/// 요금 통계 섹션 (PHASE 37) — Senior(본인 통계)/Guardian(연결된 어르신
/// 통계) 양쪽이 그대로 재사용한다. 계산은 `FeeStatisticsCalculator`
/// (ondam_models, 순수 Dart)가 담당하고, 이 위젯은 표시만 한다
/// (riverpod.md: "계산 로직은 UI에 직접 작성하지 않는다"). 두 앱 어디에도
/// app-specific 의존성(Provider 등)이 없어 design_system에 둘 수 있다 —
/// 어르신 선택 UI(`AppElderSwitcher`)는 이 위젯의 책임이 아니라 호출하는
/// 화면의 책임이다(Guardian은 이미 선택된 어르신의 `records`를 넘겨준다).
///
/// 월별/연별 전환은 이 화면 안에서만 쓰는 단순 UI 상태라 전역 Provider로
/// 만들지 않는다.
class AppFeeStatisticsSection extends StatefulWidget {
  const AppFeeStatisticsSection({
    super.key,
    required this.records,
    required this.labels,
  });

  final List<AnalysisResult> records;
  final AppFeeStatisticsLabels labels;

  @override
  State<AppFeeStatisticsSection> createState() =>
      _AppFeeStatisticsSectionState();
}

class _AppFeeStatisticsSectionState extends State<AppFeeStatisticsSection> {
  _FeePeriodView _view = _FeePeriodView.monthly;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final now = DateTime.now();
    final overall = FeeStatisticsCalculator.overall(widget.records);

    if (overall.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: AppEmptyState(message: labels.emptyMessage),
      );
    }

    final monthly = FeeStatisticsCalculator.monthly(
      widget.records,
      end: now,
      months: 12,
    );
    final points = monthly
        .map(
          (m) => FeeChartPoint(
            label: labels.monthLabelBuilder(DateTime(m.year, m.month)),
            amountKrw: m.hasData ? m.summary.totalKrw : null,
            detail: labels.countLabelBuilder(m.summary.count),
          ),
        )
        .toList();

    final years = FeeStatisticsCalculator.extractPoints(
      widget.records,
    ).map((p) => p.date.year).toSet();
    final startYear = years.isEmpty
        ? now.year
        : years.reduce((a, b) => a < b ? a : b);
    final yearly = FeeStatisticsCalculator.yearly(
      widget.records,
      end: now,
      startYear: startYear,
    );
    final yearlyPoints = yearly
        .map(
          (y) => FeeChartPoint(
            label: labels.yearLabelBuilder(DateTime(y.year)),
            amountKrw: y.hasData ? y.summary.totalKrw : null,
            detail: labels.countLabelBuilder(y.summary.count),
          ),
        )
        .toList();

    final isMonthly = _view == _FeePeriodView.monthly;
    final currentPoints = isMonthly ? points : yearlyPoints;
    final selected =
        _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < currentPoints.length
        ? currentPoints[_selectedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: labels.totalFeeLabel,
                value: formatKrw(overall.totalKrw),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: labels.averageFeeLabel,
                value: formatKrw(overall.averageKrw),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: labels.maxFeeLabel,
                value: formatKrw(overall.maxKrw),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: labels.recordCountLabel,
                value: labels.countLabelBuilder(overall.count),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _PeriodToggleButton(
                label: labels.monthlyToggleLabel,
                semanticLabel: labels.toggleSemanticSuffix(
                  labels.monthlyToggleLabel,
                ),
                selected: isMonthly,
                onTap: () => setState(() {
                  _view = _FeePeriodView.monthly;
                  _selectedIndex = null;
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PeriodToggleButton(
                label: labels.yearlyToggleLabel,
                semanticLabel: labels.toggleSemanticSuffix(
                  labels.yearlyToggleLabel,
                ),
                selected: !isMonthly,
                onTap: () => setState(() {
                  _view = _FeePeriodView.yearly;
                  _selectedIndex = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          isMonthly ? labels.monthlyTrendTitle : labels.yearlyTrendTitle,
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFeeTrendChart(
          points: currentPoints,
          emptyMessage: labels.chartEmptyMessage,
          semanticNoDataLabel: labels.chartSemanticNoDataLabel,
          semanticSummaryBuilder: labels.chartSemanticSummaryBuilder,
          selectedIndex: _selectedIndex,
          onSelect: (index) => setState(() => _selectedIndex = index),
        ),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected.label, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                if (selected.hasData) ...[
                  AppInfoRow(
                    label: labels.totalFeeLabel,
                    value: formatKrw(selected.amountKrw!),
                  ),
                  AppInfoRow(
                    label: labels.recordCountLabel,
                    value: selected.detail ?? '',
                  ),
                ] else
                  Text(
                    labels.noDataInPeriodMessage,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          labels.footnote,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PeriodToggleButton extends StatelessWidget {
  const _PeriodToggleButton({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: selected ? onPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
