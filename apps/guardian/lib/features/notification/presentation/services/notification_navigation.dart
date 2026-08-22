import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../app/router/root_navigator_key.dart';
import '../../../../core/auth/pin_verified_provider.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_di_providers.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';

/// Deep-link orchestration lives in `notification` (not `analysis`) by
/// design — architecture.md: "알림 수신 후 여러 feature 화면으로의 딥링크
/// 오케스트레이션이 필요해 순수 core/패키지보다 feature 계층이 적합". Reuses
/// `AnalysisRecordDetailPage`/`getAnalysisRecordsUseCaseProvider` as-is
/// instead of building a parallel screen or query.

/// Pure lookup, split out so it's unit-testable without Riverpod/Navigator
/// (same pattern as `idle_timeout_controller.dart`'s `shouldRelock`).
AnalysisResult? findNotificationTarget(
  List<AnalysisResult> records,
  String analysisResultId,
) {
  for (final record in records) {
    if (record.id == analysisResultId) return record;
  }
  return null;
}

/// [data] is expected to carry `elder_id`/`analysis_result_id` (the risk-
/// alert payload contract — see `NotificationItem` doc comment). Silently
/// does nothing if the payload doesn't follow that contract or the record
/// can't be found (e.g. already deleted) — there is no sensible fallback UI
/// for "a push arrived but we don't know what it's about".
Future<void> resolveAndNavigateToAnalysisDetail(
  Ref ref,
  Map<String, dynamic> data,
) async {
  final elderId = data['elder_id'] as String?;
  final analysisResultId = data['analysis_result_id'] as String?;
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
  if (record == null) return;

  rootNavigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => AnalysisRecordDetailPage(result: record)),
  );
}

/// Holds a notification tap's `data` payload when it arrives while the PIN
/// gate is still locked. `null` means there is nothing pending.
///
/// Root cause (실기기 Phase 8 검증, background-tap 딥링크 실패): go_router는
/// 선언적 라우터라 `pinVerifiedProvider`가 바뀔 때마다 `_RouterRefreshNotifier`가
/// `redirect`를 재평가해 페이지 스택을 현재 위치 기준으로 다시 만든다
/// (app_router.dart). PIN이 아직 잠긴 상태에서 [resolveAndNavigateToAnalysisDetail]이
/// `rootNavigatorKey` 위에 `AnalysisRecordDetailPage`를 imperative하게 push해도,
/// go_router는 그 라우트의 존재를 모르므로 PIN 해제 직후의 `/home` 리다이렉트
/// 리빌드가 스택을 통째로 교체하면서 함께 사라진다. 그래서 잠긴 동안 도착한
/// 알림은 여기에 저장해두고, PIN 해제가 실제로 끝난 뒤([PushNotificationController]가
/// `pinVerifiedProvider`의 false→true 전환을 감지해) 다시 처리한다.
class PendingNotificationTargetNotifier
    extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void set(Map<String, dynamic> data) => state = data;
  void clear() => state = null;
}

final pendingNotificationTargetProvider =
    NotifierProvider<PendingNotificationTargetNotifier, Map<String, dynamic>?>(
      PendingNotificationTargetNotifier.new,
    );

/// Common entry point for local-notification taps and FCM foreground/
/// background/terminated taps (`PushNotificationController`). PIN이 이미
/// 풀려 있으면 즉시 이동하고(기존 동작 그대로), 잠겨 있으면
/// [pendingNotificationTargetProvider]에 저장만 해둔다 — 위 doc 참고.
void handleNotificationTapData(Ref ref, Map<String, dynamic> data) {
  if (!ref.read(pinVerifiedProvider)) {
    ref.read(pendingNotificationTargetProvider.notifier).set(data);
    return;
  }
  unawaited(resolveAndNavigateToAnalysisDetail(ref, data));
}
