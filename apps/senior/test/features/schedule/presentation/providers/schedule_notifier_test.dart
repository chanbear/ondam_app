import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/schedule/presentation/providers/schedule_di_providers.dart';
import 'package:ondam_senior/features/schedule/presentation/providers/schedule_notifier.dart';

import '../../domain/fakes/fake_schedule_repository.dart';

Schedule _schedule(String id, String title) {
  return Schedule(
    id: id,
    elderId: 'e1',
    title: title,
    scheduledAt: DateTime(2026, 8, 25, 10, 0),
    completed: false,
    createdAt: DateTime(2026, 8, 24),
  );
}

ProviderContainer _containerWith(
  FakeScheduleRepository repository, {
  Duration? Function(int, Object)? retry,
}) {
  final container = ProviderContainer(
    retry: retry,
    overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
  );
  return container;
}

void main() {
  test('본인 일정을 성공적으로 불러오면 그대로 노출한다', () async {
    final repository = FakeScheduleRepository();
    repository.getMySchedulesResult = Ok([_schedule('s1', '병원 방문')]);
    final container = _containerWith(repository);
    addTearDown(container.dispose);

    final schedules = await container.read(scheduleListProvider.future);

    expect(schedules.single.title, '병원 방문');
    expect(repository.getMySchedulesCallCount, 1);
  });

  test('일정이 없으면 빈 목록을 반환한다 — 에러가 아니다', () async {
    final repository = FakeScheduleRepository();
    final container = _containerWith(repository);
    addTearDown(container.dispose);

    final schedules = await container.read(scheduleListProvider.future);

    expect(schedules, isEmpty);
  });

  test('Repository가 Failure를 반환하면 AsyncError로 전달된다', () async {
    final repository = FakeScheduleRepository();
    repository.getMySchedulesResult = const Err(ServerFailure());
    final container = _containerWith(repository, retry: (_, _) => null);
    addTearDown(container.dispose);

    await expectLater(
      container.read(scheduleListProvider.future),
      throwsA(isA<ServerFailure>()),
    );
  });

  group('create', () {
    test('생성이 성공하면 목록을 다시 조회한다', () async {
      final repository = FakeScheduleRepository();
      final container = _containerWith(repository);
      addTearDown(container.dispose);

      await container.read(scheduleListProvider.future);
      expect(repository.getMySchedulesCallCount, 1);

      final result = await container
          .read(scheduleListProvider.notifier)
          .create(
            title: '병원 방문',
            scheduledAt: DateTime(2026, 8, 25, 10, 0),
            isRecurring: false,
          );

      expect(result, isA<Ok<void>>());
      expect(repository.createScheduleCalls, hasLength(1));
      expect(repository.getMySchedulesCallCount, 2);
    });

    test('생성이 실패하면(빈 제목 등) 목록을 다시 조회하지 않는다', () async {
      final repository = FakeScheduleRepository();
      repository.createScheduleResult = const Err(
        ValidationFailure('일정 제목을 입력해주세요.'),
      );
      final container = _containerWith(repository);
      addTearDown(container.dispose);

      await container.read(scheduleListProvider.future);
      final callsAfterInitialLoad = repository.getMySchedulesCallCount;

      final result = await container
          .read(scheduleListProvider.notifier)
          .create(
            title: '',
            scheduledAt: DateTime(2026, 8, 25, 10, 0),
            isRecurring: false,
          );

      expect(result, isA<Err<void>>());
      expect(repository.getMySchedulesCallCount, callsAfterInitialLoad);
    });
  });

  group('toggleCompleted', () {
    test('성공하면 목록을 다시 조회한다', () async {
      final repository = FakeScheduleRepository();
      final container = _containerWith(repository);
      addTearDown(container.dispose);

      await container.read(scheduleListProvider.future);

      final result = await container
          .read(scheduleListProvider.notifier)
          .toggleCompleted('s1', true);

      expect(result, isA<Ok<void>>());
      expect(repository.toggleCompletedCalls, [('s1', true)]);
      expect(repository.getMySchedulesCallCount, 2);
    });
  });

  group('delete', () {
    test('성공하면 목록을 다시 조회한다', () async {
      final repository = FakeScheduleRepository();
      final container = _containerWith(repository);
      addTearDown(container.dispose);

      await container.read(scheduleListProvider.future);

      final result = await container
          .read(scheduleListProvider.notifier)
          .delete('s1');

      expect(result, isA<Ok<void>>());
      expect(repository.deleteScheduleCalls, ['s1']);
      expect(repository.getMySchedulesCallCount, 2);
    });

    test('실패하면 목록을 다시 조회하지 않는다', () async {
      final repository = FakeScheduleRepository();
      repository.deleteScheduleResult = const Err(ServerFailure());
      final container = _containerWith(repository);
      addTearDown(container.dispose);

      await container.read(scheduleListProvider.future);
      final callsAfterInitialLoad = repository.getMySchedulesCallCount;

      final result = await container
          .read(scheduleListProvider.notifier)
          .delete('s1');

      expect(result, isA<Err<void>>());
      expect(repository.getMySchedulesCallCount, callsAfterInitialLoad);
    });
  });
}
