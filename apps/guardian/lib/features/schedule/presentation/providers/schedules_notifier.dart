import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../connection/presentation/providers/connected_elders_provider.dart';
import 'schedule_di_providers.dart';

/// 현재 선택된 어르신의 전체 일정 — [UpcomingSchedulesNotifier]와 달리
/// 완료 여부로 거르지 않는다. 통계 탭의 "완료한 일정"/"남은 일정" 지표가
/// `Schedule.completed`(실제 컬럼)를 그대로 세기 위해 필요하다.
class SchedulesNotifier extends AsyncNotifier<List<Schedule>> {
  @override
  Future<List<Schedule>> build() async {
    final elderId = ref.watch(effectiveSelectedElderIdProvider);
    if (elderId == null) return const [];

    final result = await ref
        .read(getSchedulesForElderUseCaseProvider)
        .call(elderId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}

final schedulesProvider =
    AsyncNotifierProvider<SchedulesNotifier, List<Schedule>>(
      SchedulesNotifier.new,
    );
