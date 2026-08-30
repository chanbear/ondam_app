import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
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
        data: (records) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeeHeroCard(records: records, l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
            _RecentBillsSection(records: records, l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
            AppFeeStatisticsSection(
              records: records,
              labels: _feeStatisticsLabels(l10n),
            ),
          ],
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

/// ui-prototype `T.feeHero` — 이번 달 요금 + 전월 대비 증감을 화면 최상단에
/// 고정 표시한다(`S("stats-home")` "핵심 숫자를 최상단에 고정" 설계 근거).
/// `AppFeeStatisticsSection`(월별/연별 토글이 있는 공용 위젯, Guardian과
/// 공유)은 건드리지 않고 그 위에 이 화면 전용으로 추가한다 — 항상 "이번
/// 달" 기준으로만 보여준다(prototype도 기본 진입 상태는 월별).
class _FeeHeroCard extends StatelessWidget {
  const _FeeHeroCard({required this.records, required this.l10n});

  final List<AnalysisResult> records;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = FeeStatisticsCalculator.monthly(
      records,
      end: now,
      months: 2,
    );
    final thisMonth = months.last;
    final lastMonth = months.first;
    if (!thisMonth.hasData) return const SizedBox.shrink();

    final delta = thisMonth.summary.totalKrw - lastMonth.summary.totalKrw;
    final IconData deltaIcon;
    final String deltaLabel;
    if (delta < 0) {
      deltaIcon = Icons.trending_down;
      deltaLabel = l10n.feeHeroLessThanLastMonth(formatKrw(-delta));
    } else if (delta > 0) {
      deltaIcon = Icons.trending_up;
      deltaLabel = l10n.feeHeroMoreThanLastMonth(formatKrw(delta));
    } else {
      deltaIcon = Icons.trending_flat;
      deltaLabel = l10n.feeHeroSameAsLastMonth;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feeHeroTitle(now.month),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatKrw(thisMonth.summary.totalKrw),
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(deltaIcon, size: 16, color: AppColors.surface),
              const SizedBox(width: AppSpacing.xs),
              Text(
                deltaLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ui-prototype `S("stats-home")`/`S("stats-fee")` — 최근 고지서 목록.
/// 금액을 추출한 문서 기록만(경고문 기록 등은 애초에 금액이 없어 제외)
/// 최신순 상위 5건을 보여주고, 탭하면 이미 있는 [AnalysisRecordDetailPage]로
/// 이동한다 — prototype의 "고지서 상세"(고객번호/사용기간/세부내역 등)는
/// 우리 `AnalysisResult`에 그 필드들이 없어(구조화 안 된 자유 텍스트
/// `structuredFields`만 있음) 새로 만들면 빈 값을 보여주게 된다. 있는
/// 데이터(요약/위험도/금액)를 정직하게 보여주는 기존 상세 화면을 그대로
/// 재사용한다.
class _RecentBillsSection extends StatelessWidget {
  const _RecentBillsSection({required this.records, required this.l10n});

  final List<AnalysisResult> records;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bills = records.where((r) => r.billingAmountKrw != null).toList()
      ..sort(
        (a, b) => (b.billingDate ?? b.createdAt).compareTo(
          a.billingDate ?? a.createdAt,
        ),
      );
    final recent = bills.take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.recentBillsTitle, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, bill) in recent.indexed)
                _RecentBillRow(
                  result: bill,
                  showDivider: index != recent.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentBillRow extends StatelessWidget {
  const _RecentBillRow({required this.result, required this.showDivider});

  final AnalysisResult result;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final date = result.billingDate ?? result.createdAt;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisRecordDetailPage(result: result),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: showDivider
              ? const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(date),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatKrw(result.billingAmountKrw!),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
