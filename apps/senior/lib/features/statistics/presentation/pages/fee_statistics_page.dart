import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';

/// 요금 통계 (PHASE 37) — 본인의 `analysis_results` 중 금액을 신뢰성 있게
/// 추출한 문서 기록만으로 계산한다. 데이터 소스/계산 로직 모두 새로 만들지
/// 않고 기존 `analysis` feature의 `analysisRecordsProvider`
/// (`FeeStatisticsCalculator`는 ondam_models, `AppFeeStatisticsSection`은
/// ondam_design_system — Guardian과 동일)를 그대로 재사용한다.
class FeeStatisticsPage extends ConsumerWidget {
  const FeeStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisRecordsProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.feeStatisticsTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: state.when(
        loading: () => AppLoading(message: l10n.feeStatisticsLoadingMessage),
        error: (error, _) {
          final message = error is Failure
              ? error.message
              : l10n.feeStatisticsLoadError;
          return AppError(
            message: message,
            onRetry: () => ref.invalidate(analysisRecordsProvider),
          );
        },
        data: (records) => AppFeeStatisticsSection(
          records: records,
          labels: _feeStatisticsLabels(l10n),
        ),
      ),
    );
  }
}

/// [AppFeeStatisticsSection]은 앱 무관 공용 위젯이라 자체 `AppLocalizations`가
/// 없다 — 이 앱의 l10n에서 라벨 번들을 만들어 전달한다(Guardian
/// `statistics_tab_page.dart`의 동일 헬퍼와 같은 이유).
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
