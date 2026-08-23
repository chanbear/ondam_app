import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/demographics.dart';
import 'demographics_di_providers.dart';

/// `RegionNotifier`와 동일한 패턴 — 저장 후 요청 값을 그대로 믿지 않고
/// 서버에서 다시 조회한다.
class DemographicsNotifier extends AsyncNotifier<Demographics?> {
  @override
  Future<Demographics?> build() async {
    final result = await ref.read(getMyDemographicsUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Result<void>> save(Demographics demographics) async {
    final result = await ref
        .read(saveDemographicsUseCaseProvider)
        .call(demographics);
    if (result case Ok()) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}

final demographicsProvider =
    AsyncNotifierProvider<DemographicsNotifier, Demographics?>(
      DemographicsNotifier.new,
    );
