import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/benefit_service.dart';
import '../../domain/entities/benefit_service_detail.dart';
import 'benefit_service_di_providers.dart';

/// 화면 하나에서만 쓰는 단순 비동기 조회(재시도는 `ref.invalidate`) —
/// riverpod.md의 "재시도/재계산 로직이 없을 때는 FutureProvider" 원칙,
/// `autoDispose`로 화면을 벗어나면 폐기된다.
final benefitServiceDetailProvider = FutureProvider.autoDispose
    .family<BenefitServiceDetail, ({String id, BenefitServiceSource source})>(
      (ref, args) async {
        final result = await ref
            .read(getBenefitServiceDetailUseCaseProvider)
            .call(args.id, args.source);
        return switch (result) {
          Ok(:final value) => value,
          Err(:final failure) => throw failure,
        };
      },
    );
