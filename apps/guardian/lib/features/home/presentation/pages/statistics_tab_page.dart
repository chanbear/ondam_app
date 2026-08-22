import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../analysis/domain/analysis_stats.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';

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
          child: AppSectionHeader(title: '통계'),
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
              ? const AppEmptyState(message: '아직 연결된 어르신이 없습니다.')
              : recordsState.when(
                  loading: () => const AppLoading(),
                  error: (error, _) => AppError(
                    message: '통계를 불러오지 못했어요.',
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

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const AppEmptyState(message: '아직 통계로 보여드릴 데이터가 없습니다.');
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
                label: '이번 달 분석 건수',
                value: '${stats.thisMonthCount}건',
                trend: stats.trendSentence,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: '위험 문자 건수',
                value: '${stats.riskyThisMonthCount}건',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: '요금 통계'),
        const SizedBox(height: AppSpacing.sm),
        AppFeeStatisticsSection(records: records),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: '고지서 정보'),
        Text(
          '고지서 통계 항목은 아직 결정되지 않았어요. 기록에 담긴 원본 정보만 보여드려요.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (billRecords.isEmpty)
          const AppEmptyState(message: '아직 고지서 정보가 없습니다.')
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
                      AppInfoRow(label: entry.key, value: '${entry.value}'),
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
