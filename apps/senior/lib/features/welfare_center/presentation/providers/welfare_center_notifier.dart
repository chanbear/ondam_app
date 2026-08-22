import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../domain/entities/senior_center.dart';
import 'welfare_center_di_providers.dart';

/// `null`은 "아직 검색을 시도하지 않음"이라는 정직한 초기 상태 — 화면
/// 진입과 동시에 자동 검색하지 않고, "내 주변 경로당 찾기" 버튼을 눌렀을
/// 때만 검색한다(요구사항 30 UX 흐름).
class WelfareCenterNotifier extends AsyncNotifier<List<SeniorCenter>?> {
  @override
  Future<List<SeniorCenter>?> build() async => null;

  Future<void> search() async {
    state = const AsyncLoading();
    final region = ref.read(regionProvider).value;
    final result = await ref
        .read(searchWelfareCentersUseCaseProvider)
        .call(region);
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final welfareCenterNotifierProvider =
    AsyncNotifierProvider<WelfareCenterNotifier, List<SeniorCenter>?>(
      WelfareCenterNotifier.new,
    );
