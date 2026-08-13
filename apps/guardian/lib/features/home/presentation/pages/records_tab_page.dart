import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';

/// 기록 탭 — 선택된 어르신의 전체 분석 기록(`analysis_results`, RLS로
/// accepted 연결만 조회 가능). `schedule`은 별도 domain으로 분리되어
/// 있고 이번 Phase 범위에 없어 이 화면에 합치지 않는다(Phase 6 지시 11).
class RecordsTabPage extends ConsumerWidget {
  const RecordsTabPage({super.key});

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
          child: AppSectionHeader(title: '기록'),
        ),
        Expanded(
          child: elders.isEmpty
              ? const AppEmptyState(message: '아직 연결된 어르신이 없습니다.')
              : recordsState.when(
                  loading: () => const AppLoading(),
                  error: (error, _) => AppError(
                    message: '분석 기록을 불러오지 못했어요.',
                    onRetry: () => ref.invalidate(analysisRecordsProvider),
                  ),
                  data: (records) {
                    if (records.isEmpty) {
                      return const AppEmptyState(message: '아직 분석 기록이 없습니다.');
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: records.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return AnalysisRecordCard(
                          result: record,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnalysisRecordDetailPage(result: record),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
