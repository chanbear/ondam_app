import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../domain/entities/local_gov_office.dart';
import 'local_gov_office_di_providers.dart';

/// `regionProvider`가 갱신되면(예: 프로필에서 지역 저장 후) 자동으로
/// 재조회한다 — `BenefitServiceNotifier`와 동일한 "지역 기반 자동 조회"
/// 패턴. support_page.dart가 이 provider를 지역이 이미 확인된 뒤에만
/// 그린다(지역이 없을 때의 CTA는 `regionProvider`로 별도 처리).
class LocalGovOfficeNotifier extends AsyncNotifier<LocalGovOffice?> {
  @override
  Future<LocalGovOffice?> build() async {
    final region = await ref.watch(regionProvider.future);
    final result = await ref
        .read(searchLocalGovOfficeUseCaseProvider)
        .call(region);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}

final localGovOfficeNotifierProvider =
    AsyncNotifierProvider<LocalGovOfficeNotifier, LocalGovOffice?>(
      LocalGovOfficeNotifier.new,
    );
