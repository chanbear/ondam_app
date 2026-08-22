import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';

/// 기록 탭 — 로그인한 사용자 본인의 `analysis_results`를 최신순으로 보여준다
/// (PHASE 10). 다른 탭에서 새로 분석한 결과가 `IndexedStack` 유지 특성상
/// 자동으로 반영되지 않으므로, pull-to-refresh로 다시 불러올 수 있게 한다.
class RecordsTabPage extends ConsumerWidget {
  const RecordsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisRecordsProvider);

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
          child: state.when(
            loading: () => const AppLoading(message: '기록을 불러오고 있어요'),
            error: (error, _) {
              final message = error is Failure
                  ? error.message
                  : '기록을 불러오는 중 문제가 발생했어요.';
              return AppError(
                message: message,
                onRetry: () => ref.invalidate(analysisRecordsProvider),
              );
            },
            data: (records) {
              if (records.isEmpty) {
                return const AppEmptyState(
                  message: '아직 분석한 기록이 없습니다.\n문서 찍기나 문자 보기를 이용해보세요.',
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(analysisRecordsProvider.future),
                child: ListView.separated(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
