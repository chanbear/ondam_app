import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../app/router/root_navigator_key.dart';
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
