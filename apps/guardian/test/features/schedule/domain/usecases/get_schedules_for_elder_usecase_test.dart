import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/schedule/domain/usecases/get_schedules_for_elder_usecase.dart';
import 'package:ondam_models/ondam_models.dart';

import '../fakes/fake_schedule_repository.dart';

void main() {
  test('elderId를 Repository에 그대로 전달한다', () async {
    final repository = FakeScheduleRepository();
    final useCase = GetSchedulesForElderUseCase(repository);

    await useCase('elder-1');

    expect(repository.getSchedulesForElderCalls, ['elder-1']);
  });

  test('일정이 없으면 빈 목록을 그대로 반환한다(가짜 데이터로 채우지 않음)', () async {
    final repository = FakeScheduleRepository();
    repository.getSchedulesForElderResult = const Ok(<Schedule>[]);
    final useCase = GetSchedulesForElderUseCase(repository);

    final result = await useCase('elder-1');

    expect(result, isA<Ok<List<Schedule>>>());
    expect((result as Ok<List<Schedule>>).value, isEmpty);
  });

  test('실제 Schedule 목록을 그대로 반환한다', () async {
    final repository = FakeScheduleRepository();
    final schedule = Schedule(
      id: 's1',
      elderId: 'elder-1',
      title: '병원 방문',
      scheduledAt: DateTime(2026, 8, 25, 10, 0),
      completed: false,
      createdAt: DateTime(2026, 8, 24),
    );
    repository.getSchedulesForElderResult = Ok([schedule]);
    final useCase = GetSchedulesForElderUseCase(repository);

    final result = await useCase('elder-1');

    expect(result, isA<Ok<List<Schedule>>>());
    expect((result as Ok<List<Schedule>>).value, [schedule]);
  });

  test('Repository 실패(RLS 거부 등)를 그대로 전달한다', () async {
    final repository = FakeScheduleRepository();
    repository.getSchedulesForElderResult = const Err(AuthFailure());
    final useCase = GetSchedulesForElderUseCase(repository);

    final result = await useCase('elder-1');

    expect(result, isA<Err<List<Schedule>>>());
  });
}
