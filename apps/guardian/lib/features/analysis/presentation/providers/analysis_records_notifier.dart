import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../connection/presentation/providers/connected_elders_provider.dart';
import 'analysis_di_providers.dart';

/// Analysis records for the currently selected elder — shared by the home/
/// records/notification/statistics tabs so they don't each issue their own
/// query. `build()` watches `selectedElderIdProvider` directly, so switching
/// elders in `AppElderSwitcher` automatically refetches (riverpod.md:
/// Provider가 자동으로 의존성을 추적).
class AnalysisRecordsNotifier extends AsyncNotifier<List<AnalysisResult>> {
  @override
  Future<List<AnalysisResult>> build() async {
    final elderId = ref.watch(selectedElderIdProvider);
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
