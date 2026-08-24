import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/schedule/domain/usecases/create_schedule_usecase.dart';

import '../fakes/fake_schedule_repository.dart';

void main() {
  test('제목이 비어있으면 Repository를 호출하지 않고 ValidationFailure를 반환한다', () async {
    final repository = FakeScheduleRepository();
    final useCase = CreateScheduleUseCase(repository);

    final result = await useCase(
      title: '   ',
      scheduledAt: DateTime(2026, 8, 25, 10, 0),
      isRecurring: false,
    );

    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.createScheduleCalls, isEmpty);
  });

  test('반복 일정인데 시각을 지정하지 않으면 ValidationFailure를 반환한다', () async {
    final repository = FakeScheduleRepository();
    final useCase = CreateScheduleUseCase(repository);

    final result = await useCase(
      title: '혈압약 복용',
      scheduledAt: DateTime(2026, 8, 25, 8, 30),
      isRecurring: true,
    );

    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.createScheduleCalls, isEmpty);
  });

  test('반복 시각이 범위를 벗어나면 ValidationFailure를 반환한다', () async {
    final repository = FakeScheduleRepository();
    final useCase = CreateScheduleUseCase(repository);

    final result = await useCase(
      title: '혈압약 복용',
      scheduledAt: DateTime(2026, 8, 25, 8, 30),
      isRecurring: true,
      recurrenceHour: 24,
      recurrenceMinute: 0,
    );

    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.createScheduleCalls, isEmpty);
  });

  test(
    '비반복 일정은 제목/일시만으로 Repository를 호출한다 — recurrenceHour/Minute는 null로 넘긴다',
    () async {
      final repository = FakeScheduleRepository();
      final useCase = CreateScheduleUseCase(repository);

      final result = await useCase(
        title: '  병원 방문  ',
        scheduledAt: DateTime(2026, 8, 25, 10, 0),
        isRecurring: false,
      );

      expect(result, isA<Ok<void>>());
      expect(repository.createScheduleCalls.single['title'], '병원 방문');
      expect(repository.createScheduleCalls.single['isRecurring'], isFalse);
      expect(repository.createScheduleCalls.single['recurrenceHour'], isNull);
      expect(repository.createScheduleCalls.single['recurrenceMinute'], isNull);
    },
  );

  test('반복 일정은 recurrenceHour/Minute를 그대로 Repository에 전달한다', () async {
    final repository = FakeScheduleRepository();
    final useCase = CreateScheduleUseCase(repository);

    final result = await useCase(
      title: '혈압약 복용',
      scheduledAt: DateTime(2026, 8, 25, 8, 30),
      isRecurring: true,
      recurrenceHour: 8,
      recurrenceMinute: 30,
    );

    expect(result, isA<Ok<void>>());
    expect(repository.createScheduleCalls.single['recurrenceHour'], 8);
    expect(repository.createScheduleCalls.single['recurrenceMinute'], 30);
  });

  test('Repository 실패를 그대로 전달한다', () async {
    final repository = FakeScheduleRepository();
    repository.createScheduleResult = const Err(ServerFailure());
    final useCase = CreateScheduleUseCase(repository);

    final result = await useCase(
      title: '병원 방문',
      scheduledAt: DateTime(2026, 8, 25, 10, 0),
      isRecurring: false,
    );

    expect((result as Err<void>).failure, isA<ServerFailure>());
  });
}
