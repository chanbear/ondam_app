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
  const AppFeeStatisticsSection({super.key, required this.records});

  final List<AnalysisResult> records;

  @override
  State<AppFeeStatisticsSection> createState() =>
      _AppFeeStatisticsSectionState();
}

class _AppFeeStatisticsSectionState extends State<AppFeeStatisticsSection> {
  _FeePeriodView _view = _FeePeriodView.monthly;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overall = FeeStatisticsCalculator.overall(widget.records);

    if (overall.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: AppEmptyState(
          message: '아직 요금 통계가 없습니다.\n고지서나 요금서를 분석하면 통계가 만들어집니다.',
        ),
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
            label: '${m.month}월',
            amountKrw: m.hasData ? m.summary.totalKrw : null,
            detail: '${m.summary.count}건',
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
            label: '${y.year}년',
            amountKrw: y.hasData ? y.summary.totalKrw : null,
            detail: '${y.summary.count}건',
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
                label: '총 요금',
                value: formatKrw(overall.totalKrw),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: '평균 요금',
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
                label: '최고 요금',
                value: formatKrw(overall.maxKrw),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(label: '요금 내역', value: '${overall.count}건'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _PeriodToggleButton(
                label: '월별',
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
                label: '연별',
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
          isMonthly ? '월별 요금 추이' : '연별 요금 추이',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFeeTrendChart(
          points: currentPoints,
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
                    label: '총 요금',
                    value: formatKrw(selected.amountKrw!),
                  ),
                  AppInfoRow(label: '건수', value: selected.detail ?? ''),
                ] else
                  Text(
                    '이 기간에는 요금 기록이 없습니다.',
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
          '분석된 고지서/요금서의 금액을 기준으로 계산합니다. AI가 금액을 추출하지 못한 기록은 제외됩니다.',
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label 보기',
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
