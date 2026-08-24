import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
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
          child: AppSectionHeader(title: l10n.navRecords),
        ),
        Expanded(
          child: elders.isEmpty
              ? AppEmptyState(message: l10n.noConnectedEldersMessage)
              : recordsState.when(
                  loading: () => const AppLoading(),
                  error: (error, _) => AppError(
                    message: l10n.recordsLoadError,
                    onRetry: () => ref.invalidate(analysisRecordsProvider),
                  ),
                  data: (records) {
                    if (records.isEmpty) {
                      return AppEmptyState(message: l10n.recordsEmptyMessage);
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
