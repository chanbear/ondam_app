import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

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
    final elders = ref.watch(connectedEldersProvider);

    if (elders.isEmpty) {
      return AppEmptyState(
        icon: Icons.family_restroom_outlined,
        message: '아직 연결된 어르신이 없습니다.',
        actionLabel: '어르신 연결하기',
        onAction: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ConnectionScanPage())),
      );
    }

    final selectedId = ref.watch(selectedElderIdProvider) ?? elders.first.id;
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
        AppSectionHeader(title: '최근 활동'),
        _RecentActivity(recordsState: recordsState),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: '다가오는 일정'),
        const AppEmptyState(message: '예정된 일정이 없어요.'),
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
    return recordsState.when(
      loading: () => const AppLoading(),
      error: (error, _) => const AppStatusCard(
        message: '안심 상태를 불러오지 못했어요.',
        icon: Icons.error_outline,
      ),
      data: (records) {
        final worst = RiskSummary.worst(records);
        return switch (worst) {
          RiskLevel.dangerous => const AppAlertCard(
            level: RiskLevel.dangerous,
            title: '확인이 필요한 활동이 있어요',
            description: '기록 탭에서 자세한 내용을 확인해주세요.',
          ),
          RiskLevel.caution => const AppAlertCard(
            level: RiskLevel.caution,
            title: '주의가 필요한 활동이 있어요',
            description: '기록 탭에서 자세한 내용을 확인해주세요.',
          ),
          _ => const AppStatusCard(
            message: '오늘도 평안하세요.',
            description: '아직 특별한 알림이 없어요.',
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
    return recordsState.when(
      loading: () => const AppLoading(),
      error: (error, _) => AppError(
        message: '최근 활동을 불러오지 못했어요.',
        onRetry: () => ref.invalidate(analysisRecordsProvider),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const AppEmptyState(message: '아직 활동 기록이 없어요.');
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
