import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import 'analysis_records_di_providers.dart';

/// Newest-first list of the signed-in user's own analysis records.
/// AsyncNotifier so `RecordsTabPage` can drive it with `.when(...)` and
/// pull-to-refresh via `ref.refresh(analysisRecordsProvider.future)`
/// (riverpod.md).
class AnalysisRecordsNotifier extends AsyncNotifier<List<AnalysisResult>> {
  @override
  Future<List<AnalysisResult>> build() async {
    final result = await ref.read(getMyAnalysisRecordsUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// 문서/문자 결과 화면과 기록 상세 화면이 모두 이 메서드 하나로
  /// "확인 완료"를 처리한다(ONDAM 2.0 PHASE 30) — 확인이 성공하면 이 목록도
  /// 함께 다시 조회해서, 목록 → 상세 → 확인 완료 → 다시 목록 → 다시 상세로
  /// 돌아왔을 때 캐시된 옛 `confirmedAt: null` 값이 남아 "확인 완료" 버튼이
  /// 되살아나 보이지 않게 한다(`RegionNotifier.save()`와 동일한
  /// invalidateSelf+재조회 패턴, riverpod.md).
  Future<Result<void>> confirm(String analysisResultId) async {
    final result = await ref
        .read(confirmAnalysisResultUseCaseProvider)
        .call(analysisResultId);
    if (result case Ok()) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}

final analysisRecordsProvider =
    AsyncNotifierProvider<AnalysisRecordsNotifier, List<AnalysisResult>>(
      AnalysisRecordsNotifier.new,
    );
