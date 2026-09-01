import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';

/// 기록 탭에서 고를 수 있는 필터 — 이미 불러온 [AnalysisResult] 목록을
/// 화면에서만 걸러 보여주는 순수 UI 상태다(서버에 다시 요청하지 않는다).
enum _RecordFilter { all, danger, document, message }

/// 기록 탭 — 선택된 어르신의 전체 분석 기록(`analysis_results`, RLS로
/// accepted 연결만 조회 가능). `schedule`은 별도 domain으로 분리되어
/// 있고 이번 Phase 범위에 없어 이 화면에 합치지 않는다(Phase 6 지시 11).
class RecordsTabPage extends ConsumerStatefulWidget {
  const RecordsTabPage({super.key});

  @override
  ConsumerState<RecordsTabPage> createState() => _RecordsTabPageState();
}

class _RecordsTabPageState extends ConsumerState<RecordsTabPage> {
  _RecordFilter _filter = _RecordFilter.all;

  List<AnalysisResult> _applyFilter(List<AnalysisResult> records) {
    return switch (_filter) {
      _RecordFilter.all => records,
      _RecordFilter.danger =>
        records
            .where(
              (r) =>
                  r.riskLevel == RiskLevel.caution ||
                  r.riskLevel == RiskLevel.dangerous,
            )
            .toList(),
      _RecordFilter.document =>
        records.where((r) => r.type == AnalysisType.document).toList(),
      _RecordFilter.message =>
        records.where((r) => r.type == AnalysisType.message).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
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
        if (elders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _FilterRow(
              selected: _filter,
              onSelect: (filter) => setState(() => _filter = filter),
            ),
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
                  data: (allRecords) {
                    if (allRecords.isEmpty) {
                      return AppEmptyState(message: l10n.recordsEmptyMessage);
                    }
                    final records = _applyFilter(allRecords);
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelect});

  final _RecordFilter selected;
  final ValueChanged<_RecordFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <(_RecordFilter, String)>[
      (_RecordFilter.all, l10n.filterAllLabel),
      (_RecordFilter.danger, l10n.filterDangerLabel),
      (_RecordFilter.document, l10n.filterDocumentLabel),
      (_RecordFilter.message, l10n.filterMessageLabel),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          for (final (filter, label) in options) ...[
            ChoiceChip(
              label: Text(label),
              selected: selected == filter,
              onSelected: (_) => onSelect(filter),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
