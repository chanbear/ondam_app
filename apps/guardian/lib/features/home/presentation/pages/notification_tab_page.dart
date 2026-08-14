import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_di_providers.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notifications_notifier.dart';
import '../../../notification/presentation/services/notification_navigation.dart';
import '../../../notification/presentation/widgets/notification_list_item.dart';

/// 알림 탭 — 두 구간으로 구성된다:
/// 1) "실시간 알림": 실제 Push 이벤트 로그(`notifications` 테이블,
///    technical-decisions.md §1-4/§1-10, Phase 8에서 신규 조회).
/// 2) "위험 기록": 주의/위험으로 판정된 분석 기록(feature-spec.md KEEP-13,
///    Phase 6부터 있던 뷰 — `notifications` 파이프라인(위험 분석 →
///    알림 생성)이 아직 백엔드에 없는 동안에도 여기서 이미 저장된
///    `analysis_results`를 계속 보여준다).
/// 두 구간 모두 원시 로그 나열이 아니라 이미 있던 필터링 원칙(Phase 6
/// 지시 6)을 유지한다.
class NotificationTabPage extends ConsumerWidget {
  const NotificationTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elders = ref.watch(connectedEldersProvider);
    final notificationsState = ref.watch(notificationsProvider);
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
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppSectionHeader(title: '실시간 알림'),
                    const SizedBox(height: AppSpacing.sm),
                    ...notificationsState.when(
                      loading: () => const [AppLoading()],
                      error: (error, _) => [
                        AppError(
                          message: '알림을 불러오지 못했어요.',
                          onRetry: () => ref.invalidate(notificationsProvider),
                        ),
                      ],
                      data: (notifications) {
                        if (notifications.isEmpty) {
                          return const [
                            AppEmptyState(message: '아직 받은 알림이 없습니다.'),
                          ];
                        }
                        return [
                          for (final item in notifications) ...[
                            NotificationListItem(
                              item: item,
                              onTap: () =>
                                  _handleNotificationTap(context, ref, item),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ];
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppSectionHeader(title: '위험 기록'),
                    const SizedBox(height: AppSpacing.sm),
                    ...recordsState.when(
                      loading: () => const [AppLoading()],
                      error: (error, _) => [
                        AppError(
                          message: '기록을 불러오지 못했어요.',
                          onRetry: () =>
                              ref.invalidate(analysisRecordsProvider),
                        ),
                      ],
                      data: (records) {
                        final riskyRecords = records
                            .where(
                              (r) =>
                                  r.riskLevel == RiskLevel.caution ||
                                  r.riskLevel == RiskLevel.dangerous,
                            )
                            .toList();
                        if (riskyRecords.isEmpty) {
                          return const [
                            AppEmptyState(message: '아직 위험 기록이 없습니다.'),
                          ];
                        }
                        return [
                          for (final record in riskyRecords) ...[
                            AnalysisRecordCard(
                              result: record,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AnalysisRecordDetailPage(result: record),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ];
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    await ref.read(notificationsProvider.notifier).markAsRead(item.id);

    final elderId = item.elderId;
    final analysisResultId = item.analysisResultId;
    if (elderId == null || analysisResultId == null) return;

    ref.read(selectedElderIdProvider.notifier).select(elderId);
    final result = await ref
        .read(getAnalysisRecordsUseCaseProvider)
        .call(elderId);
    final records = switch (result) {
      Ok(:final value) => value,
      Err() => const <AnalysisResult>[],
    };

    final record = findNotificationTarget(records, analysisResultId);
    if (record == null || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisRecordDetailPage(result: record),
      ),
    );
  }
}
