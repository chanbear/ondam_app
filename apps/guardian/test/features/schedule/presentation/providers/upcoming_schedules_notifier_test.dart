import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/connected_elders_provider.dart';
import 'package:ondam_guardian/features/schedule/domain/usecases/get_schedules_for_elder_usecase.dart';
import 'package:ondam_guardian/features/schedule/presentation/providers/schedule_di_providers.dart';
import 'package:ondam_guardian/features/schedule/presentation/providers/upcoming_schedules_notifier.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/fakes/fake_schedule_repository.dart';

Schedule _schedule(String elderId, String title, {bool completed = false}) {
  return Schedule(
    id: 's-$elderId-$title',
    elderId: elderId,
    title: title,
    scheduledAt: DateTime(2026, 8, 25, 10, 0),
    completed: completed,
    createdAt: DateTime(2026, 8, 24),
  );
}

void main() {
  test('선택된 어르신이 없으면 조회 없이 빈 목록을 반환한다', () async {
    final repository = FakeScheduleRepository();
    final container = ProviderContainer(
      overrides: [
        getSchedulesForElderUseCaseProvider.overrideWithValue(
          GetSchedulesForElderUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final schedules = await container.read(upcomingSchedulesProvider.future);

    expect(schedules, isEmpty);
    expect(repository.getSchedulesForElderCalls, isEmpty);
  });

  test('어르신을 선택하면 해당 elderId로 조회한다', () async {
    final repository = FakeScheduleRepository();
    repository.getSchedulesForElderResult = Ok([_schedule('elder-1', '병원 방문')]);
    final container = ProviderContainer(
      overrides: [
        getSchedulesForElderUseCaseProvider.overrideWithValue(
          GetSchedulesForElderUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(selectedElderIdProvider.notifier).select('elder-1');
    final schedules = await container.read(upcomingSchedulesProvider.future);

    expect(repository.getSchedulesForElderCalls, ['elder-1']);
    expect(schedules.single.title, '병원 방문');
  });

  test('완료된 일정은 제외한다', () async {
    final repository = FakeScheduleRepository();
    repository.getSchedulesForElderResult = Ok([
      _schedule('elder-1', '완료한 일정', completed: true),
      _schedule('elder-1', '남은 일정'),
    ]);
    final container = ProviderContainer(
      overrides: [
        getSchedulesForElderUseCaseProvider.overrideWithValue(
          GetSchedulesForElderUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(selectedElderIdProvider.notifier).select('elder-1');
    final schedules = await container.read(upcomingSchedulesProvider.future);

    expect(schedules.single.title, '남은 일정');
  });
}
