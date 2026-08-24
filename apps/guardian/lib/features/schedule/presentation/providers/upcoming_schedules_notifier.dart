import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../connection/presentation/providers/connected_elders_provider.dart';
import 'schedule_di_providers.dart';

/// 현재 선택된 어르신의 "다가오는 일정" — 완료하지 않은 일정만, 가까운
/// 순서로 노출한다(`ScheduleRemoteDataSource.fetchForElder`가 이미
/// `scheduled_at` 오름차순으로 정렬해 넘겨준다). 홈 탭이 이 중 앞 몇 개만
/// 잘라 보여준다(`_RecentActivity`/`_RecentNotifications`와 동일하게 자르기는
/// 위젯 책임 — `AnalysisRecordsNotifier`와 동일한
/// `effectiveSelectedElderIdProvider` watch 패턴).
class UpcomingSchedulesNotifier extends AsyncNotifier<List<Schedule>> {
  @override
  Future<List<Schedule>> build() async {
    final elderId = ref.watch(effectiveSelectedElderIdProvider);
    if (elderId == null) return const [];

    final result = await ref
        .read(getSchedulesForElderUseCaseProvider)
        .call(elderId);
    final schedules = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
    return schedules.where((schedule) => !schedule.completed).toList();
  }
}

final upcomingSchedulesProvider =
    AsyncNotifierProvider<UpcomingSchedulesNotifier, List<Schedule>>(
      UpcomingSchedulesNotifier.new,
    );
