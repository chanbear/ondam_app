import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/domain/risk_summary.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_di_providers.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../connection/presentation/pages/connection_scan_page.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notifications_notifier.dart';
import '../../../notification/presentation/services/notification_navigation.dart';
import '../../../notification/presentation/widgets/notification_list_item.dart';
import '../../../schedule/presentation/providers/upcoming_schedules_notifier.dart';
import '../../../schedule/presentation/widgets/upcoming_schedule_list_item.dart';
import '../providers/shell_tab_index_provider.dart';

/// 홈 탭 — "지금 우리 어르신 괜찮으신가"에 최상단에서 답한다
/// (ui-principles.md Guardian 1). 연결된 어르신이 없으면 Mock 프리뷰가
/// 아니라 정직한 `AppEmptyState`로 안내한다(기존 확정 사항 유지).
///
/// 정보 위계(Guardian UI Application Round 1 §6, 승인 prototype 기준):
/// 어르신 선택/상태 → 안심 상태 → 최근 알림 → 다가오는 일정 → 최근 활동.
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
    final notificationsState = ref.watch(notificationsProvider);
    final upcomingSchedulesState = ref.watch(upcomingSchedulesProvider);

    // `IndexedStack`(HomeShellPage) 자식으로 `ListView`를 곧바로 반환하면
    // 앱 최초 프레임(뷰포트 메트릭 도착 전 0x0 constraint)에 레이아웃이
    // 굳어 본문이 완전히 비어버리는 문제가 있었다(Guardian Home P0). 다른
    // 탭(RecordsTabPage 등)처럼 `Expanded`로 명시적 bounded height를 줘서
    // Viewport가 매 layout마다 실제 constraint를 다시 받도록 한다 — 콘텐츠/
    // 로직은 그대로, 레이아웃 래퍼만 추가.
    return Column(
      children: [
        Expanded(
          child: ListView(
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
              AppSectionHeader(
                title: l10n.recentNotificationsTitle,
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(shellTabIndexProvider.notifier).select(1),
                  child: Text(l10n.viewAllAction),
                ),
              ),
              _RecentNotifications(notificationsState: notificationsState),
              const SizedBox(height: AppSpacing.xl),
              AppSectionHeader(title: l10n.upcomingScheduleTitle),
              _UpcomingSchedule(scheduleState: upcomingSchedulesState),
              const SizedBox(height: AppSpacing.xl),
              AppSectionHeader(title: l10n.recentActivityTitle),
              _RecentActivity(recordsState: recordsState),
            ],
          ),
        ),
      ],
    );
  }
}

/// 최근 알림 2건 — 전체 목록은 알림 탭에서 본다("전체보기"). 탭하면
/// 알림 탭의 `_handleNotificationTap`과 동일하게 읽음 처리 후 분석 상세로
/// 이동한다(기존 read state/notification navigation 로직을 그대로
/// 재사용한다 — Guardian UI Application Round 1 §17 regression 보존).
class _RecentNotifications extends ConsumerWidget {
  const _RecentNotifications({required this.notificationsState});

  final AsyncValue<List<NotificationItem>> notificationsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return notificationsState.when(
      loading: () => const AppLoading(),
      error: (error, _) => AppError(
        message: l10n.recentNotificationsLoadError,
        onRetry: () => ref.invalidate(notificationsProvider),
      ),
      data: (notifications) {
        if (notifications.isEmpty) {
          return AppEmptyState(message: l10n.noRecentNotifications);
        }
        return Column(
          children: [
            for (final item in notifications.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NotificationListItem(
                  item: item,
                  onTap: () => _handleTap(context, ref, item),
                ),
              ),
          ],
        );
      },
    );
  }

  /// `NotificationTabPage._handleNotificationTap`과 동일한 로직(Guardian UI
  /// Application Round 1 §17 — Phase 8 notification navigation은 수정하지
  /// 않는다). 캐시된 `analysisRecordsProvider` 값을 그대로 읽지 않고
  /// usecase를 다시 호출하는 이유도 그 파일의 주석과 동일하다.
  Future<void> _handleTap(
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

/// `schedules` 테이블(analysis_results와 분리된 독립 도메인, feature-spec.md
/// MODIFY-9)을 조회한 실제 데이터로 채운다 — 완료하지 않은 일정 중 가까운
/// 3건만 보여준다(`_RecentActivity`/`_RecentNotifications`와 동일하게
/// take(N)은 위젯 책임).
class _UpcomingSchedule extends ConsumerWidget {
  const _UpcomingSchedule({required this.scheduleState});

  final AsyncValue<List<Schedule>> scheduleState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return scheduleState.when(
      loading: () => const AppLoading(),
      error: (error, _) {
        final message = error is Failure
            ? error.message
            : l10n.recentActivityLoadError;
        return AppError(
          message: message,
          onRetry: () => ref.invalidate(upcomingSchedulesProvider),
        );
      },
      data: (schedules) {
        if (schedules.isEmpty) {
          return AppEmptyState(message: l10n.noUpcomingSchedule);
        }
        return Column(
          children: [
            for (final schedule in schedules.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: UpcomingScheduleListItem(schedule: schedule),
              ),
          ],
        );
      },
    );
  }
}
