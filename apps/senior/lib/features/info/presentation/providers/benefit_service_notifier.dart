import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/demographics/presentation/providers/demographics_provider.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../domain/entities/benefit_service.dart';
import 'benefit_service_di_providers.dart';

/// 나이/성별/지역이 모두 채워지면 자동으로 검색한다(요구사항: "사람마다
/// 결과가 바뀌었으면 좋겠다" — 하드코딩 카드 대신 실시간 조건 기반 검색).
/// `demographicsProvider`/`regionProvider`가 갱신되면(예: 프로필 저장 후)
/// `build()`가 다시 실행되어 자동으로 재검색된다.
class BenefitServiceNotifier extends AsyncNotifier<List<BenefitService>?> {
  @override
  Future<List<BenefitService>?> build() async {
    final demographics = await ref.watch(demographicsProvider.future);
    final region = await ref.watch(regionProvider.future);
    final result = await ref
        .read(searchBenefitServicesUseCaseProvider)
        .call(demographics, region);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}

final benefitServiceNotifierProvider =
    AsyncNotifierProvider<BenefitServiceNotifier, List<BenefitService>?>(
      BenefitServiceNotifier.new,
    );
