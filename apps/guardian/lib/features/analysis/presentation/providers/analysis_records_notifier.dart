import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../connection/presentation/providers/connected_elders_provider.dart';
import 'analysis_di_providers.dart';

/// Analysis records for the currently selected elder — shared by the home/
/// records/notification/statistics tabs so they don't each issue their own
/// query. `build()` watches `effectiveSelectedElderIdProvider` (PHASE 37 버그
/// 수정 — 명시적 선택이 없으면 첫 번째 연결된 어르신으로 자동 대체, 어르신
/// 1명만 연결된 흔한 경우에도 정상 조회되게 한다), so switching elders in
/// `AppElderSwitcher` automatically refetches (riverpod.md: Provider가
/// 자동으로 의존성을 추적).
class AnalysisRecordsNotifier extends AsyncNotifier<List<AnalysisResult>> {
  @override
  Future<List<AnalysisResult>> build() async {
    final elderId = ref.watch(effectiveSelectedElderIdProvider);
    if (elderId == null) return const [];

    final result = await ref
        .read(getAnalysisRecordsUseCaseProvider)
        .call(elderId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}

final analysisRecordsProvider =
    AsyncNotifierProvider<AnalysisRecordsNotifier, List<AnalysisResult>>(
      AnalysisRecordsNotifier.new,
    );
