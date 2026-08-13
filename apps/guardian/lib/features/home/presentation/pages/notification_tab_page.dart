import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';

/// 알림 탭 — "받은 연락": 주의/위험으로 판정된 분석 기록만 모아 보여준다
/// (feature-spec.md KEEP-13, 안전/무위험 기록은 기록 탭에서만 확인). 원시
/// 로그 나열이 아니라 위험 있는 항목만 요약해서 보여주는 원칙(Phase 6
/// 지시 6)에 따라 `riskLevel`이 caution/dangerous인 것만 필터링한다.
class NotificationTabPage extends ConsumerWidget {
  const NotificationTabPage({super.key});

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
          child: AppSectionHeader(title: '알림'),
        ),
        Expanded(
          child: elders.isEmpty
              ? const AppEmptyState(message: '아직 연결된 어르신이 없습니다.')
              : recordsState.when(
                  loading: () => const AppLoading(),
                  error: (error, _) => AppError(
                    message: '알림을 불러오지 못했어요.',
                    onRetry: () => ref.invalidate(analysisRecordsProvider),
                  ),
                  data: (records) {
                    final riskyRecords = records
                        .where(
                          (r) =>
                              r.riskLevel == RiskLevel.caution ||
                              r.riskLevel == RiskLevel.dangerous,
                        )
                        .toList();
                    if (riskyRecords.isEmpty) {
                      return const AppEmptyState(message: '아직 받은 알림이 없습니다.');
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: riskyRecords.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final record = riskyRecords[index];
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
