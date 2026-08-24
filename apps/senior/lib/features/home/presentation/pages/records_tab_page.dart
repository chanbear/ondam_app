import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../schedule/presentation/widgets/schedule_tab_view.dart';

/// 기록 탭 — "분석 기록"/"일정" 두 서브탭으로 구성된다. 레거시 온담앱도
/// "기록 탭" 안에 분석 기록과 일정을 함께 뒀고(current-app-analysis.md),
/// `schedule`은 `analysis`에서 분리된 독립 도메인이지만(feature-spec.md
/// MODIFY-9) 화면 위치는 같은 탭 안의 서브탭으로 유지한다.
class RecordsTabPage extends StatelessWidget {
  const RecordsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: AppSectionHeader(title: l10n.myRecordsTitle),
          ),
          const TabBar(
            tabs: [
              Tab(text: '분석 기록'),
              Tab(text: '일정'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [_AnalysisRecordsView(), ScheduleTabView()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisRecordsView extends ConsumerWidget {
  const _AnalysisRecordsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisRecordsProvider);
    final l10n = AppLocalizations.of(context)!;

    return state.when(
      loading: () => AppLoading(message: l10n.recordsLoadingMessage),
      error: (error, _) {
        final message = error is Failure
            ? error.message
            : l10n.recordsLoadError;
        return AppError(
          message: message,
          onRetry: () => ref.invalidate(analysisRecordsProvider),
        );
      },
      data: (records) {
        if (records.isEmpty) {
          return AppEmptyState(message: l10n.recordsEmptyMessage);
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(analysisRecordsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final record = records[index];
              return AnalysisRecordCard(
                result: record,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnalysisRecordDetailPage(result: record),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
