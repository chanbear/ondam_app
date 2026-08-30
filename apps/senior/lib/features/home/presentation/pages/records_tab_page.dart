import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
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

/// ui-prototype `S("records")`의 안전/주의/위험 필터 칩 — 이미 불러온
/// [AnalysisResult] 목록을 화면에서만 걸러 보여주는 순수 UI 상태다(서버에
/// 다시 요청하지 않는다, 2026-08-29 프로토타입 결정과 동일).
class _AnalysisRecordsView extends ConsumerStatefulWidget {
  const _AnalysisRecordsView();

  @override
  ConsumerState<_AnalysisRecordsView> createState() =>
      _AnalysisRecordsViewState();
}

class _AnalysisRecordsViewState extends ConsumerState<_AnalysisRecordsView> {
  RiskLevel? _filter;

  @override
  Widget build(BuildContext context) {
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
        final filtered = _filter == null
            ? records
            : records.where((r) => r.riskLevel == _filter).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _RiskFilterRow(
                selected: _filter,
                onSelect: (filter) => setState(() => _filter = filter),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? AppEmptyState(message: l10n.recordsFilterEmptyMessage)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(analysisRecordsProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final record = filtered[index];
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
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// ui-prototype `.chip`/`.chip.active`(테두리+틴트 배경으로 선택 상태 표현,
/// Material 기본 파란 ChoiceChip이 아님) — 이미 다른 화면(온보딩 접근성
/// 설정 등)에서 같은 패턴에 쓰인 `AppCard.selected`를 재사용한다. Easy
/// 모드에서는 `[data-easy="true"] .chip{font-size:17px;padding:12px 18px}`에
/// 맞춰 여백/글자를 키운다.
class _RiskFilterRow extends ConsumerWidget {
  const _RiskFilterRow({required this.selected, required this.onSelect});

  final RiskLevel? selected;
  final ValueChanged<RiskLevel?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    final options = <(RiskLevel?, String)>[
      (null, l10n.recordsFilterAllLabel),
      (RiskLevel.safe, l10n.riskSafeLabel),
      (RiskLevel.caution, l10n.riskCautionLabel),
      (RiskLevel.dangerous, l10n.riskDangerousLabel),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (filter, label) in options) ...[
            AppCard(
              variant: selected == filter
                  ? AppCardVariant.selected
                  : AppCardVariant.normal,
              padding: EdgeInsets.symmetric(
                horizontal: easyMode ? AppSpacing.lg : AppSpacing.md,
                vertical: easyMode ? AppSpacing.sm : AppSpacing.xs,
              ),
              onTap: () => onSelect(filter),
              child: Text(
                label,
                style: easyMode
                    ? AppTextStyles.bodyLarge
                    : AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
