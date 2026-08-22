import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/domain/risk_summary.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../connection/presentation/pages/connection_scan_page.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';

/// 홈 탭 — "지금 우리 어르신 괜찮으신가"에 최상단에서 답한다
/// (ui-principles.md Guardian 1). 연결된 어르신이 없으면 Mock 프리뷰가
/// 아니라 정직한 `AppEmptyState`로 안내한다(기존 확정 사항 유지).
///
/// Phase 6: `connectedEldersProvider`가 실제 `guardian_links`(accepted)를
/// 소스로 쓰게 되면서 안심 상태/최근 활동도 실제 `analysis_results`
/// 조회(`analysisRecordsProvider`)로 연결한다. 실제 백엔드 AI 분석이 아직
/// 없어(Phase 4) 이 조회는 언제나 빈 결과를 돌려주는 것이 현재로선 정직한
/// 상태다 — 가짜 데이터로 채우지 않는다.
class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final elders = ref.watch(connectedEldersProvider);

    if (elders.isEmpty) {
      return AppEmptyState(
        icon: Icons.family_restroom_outlined,
        message: l10n.noConnectedEldersMessage,
        actionLabel: l10n.connectElderAction,
        onAction: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ConnectionScanPage())),
      );
    }

    final selectedId = ref.watch(effectiveSelectedElderIdProvider);
    final recordsState = ref.watch(analysisRecordsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppElderSwitcher(
          elders: elders,
          selectedElderId: selectedId,
          onSelect: (id) =>
              ref.read(selectedElderIdProvider.notifier).select(id),
        ),
        const SizedBox(height: AppSpacing.md),
        _ReassuranceCard(recordsState: recordsState),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.recentActivityTitle),
        _RecentActivity(recordsState: recordsState),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.upcomingScheduleTitle),
        AppEmptyState(message: l10n.noUpcomingSchedule),
      ],
    );
  }
}

/// 위험도(success/warning/error)와 신뢰도는 서로 다른 개념이다(Phase 6 지시
/// 5) — 여기서는 최근 기록 중 가장 심각한 위험도만 반영하고, 신뢰도는
/// 개별 기록 상세에서만 `AppConfidenceIndicator`로 보여준다.
class _ReassuranceCard extends StatelessWidget {
  const _ReassuranceCard({required this.recordsState});

  final AsyncValue<List<AnalysisResult>> recordsState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return recordsState.when(
      loading: () => const AppLoading(),
      error: (error, _) => AppStatusCard(
        message: l10n.reassuranceLoadError,
        icon: Icons.error_outline,
      ),
      data: (records) {
        final worst = RiskSummary.worst(records);
        return switch (worst) {
          RiskLevel.dangerous => AppAlertCard(
            level: RiskLevel.dangerous,
            title: l10n.dangerousAlertTitle,
            description: l10n.alertCheckRecordsDescription,
          ),
          RiskLevel.caution => AppAlertCard(
            level: RiskLevel.caution,
            title: l10n.cautionAlertTitle,
            description: l10n.alertCheckRecordsDescription,
          ),
          _ => AppStatusCard(
            message: l10n.safeStatusMessage,
            description: l10n.safeStatusDescription,
            icon: Icons.check_circle_outline,
          ),
        };
      },
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity({required this.recordsState});

  final AsyncValue<List<AnalysisResult>> recordsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return recordsState.when(
      loading: () => const AppLoading(),
      error: (error, _) => AppError(
        message: l10n.recentActivityLoadError,
        onRetry: () => ref.invalidate(analysisRecordsProvider),
      ),
      data: (records) {
        if (records.isEmpty) {
          return AppEmptyState(message: l10n.noActivityRecords);
        }
        return Column(
          children: [
            for (final record in records.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AnalysisRecordCard(
                  result: record,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnalysisRecordDetailPage(result: record),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
