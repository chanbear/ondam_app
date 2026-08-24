import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/schedule/domain/usecases/get_my_schedules_usecase.dart';

import '../fakes/fake_schedule_repository.dart';

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

void main() {
  test('Repository의 일정 목록을 그대로 반환한다', () async {
    final repository = FakeScheduleRepository();
    repository.getMySchedulesResult = Ok([_schedule('s1', '병원 방문')]);
    final useCase = GetMySchedulesUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<List<Schedule>>>());
    expect((result as Ok<List<Schedule>>).value.single.title, '병원 방문');
    expect(repository.getMySchedulesCallCount, 1);
  });

  test('일정이 없으면 빈 목록을 반환한다 — 에러가 아니다', () async {
    final repository = FakeScheduleRepository();
    final useCase = GetMySchedulesUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<List<Schedule>>>());
    expect((result as Ok<List<Schedule>>).value, isEmpty);
  });

  test('Repository 실패를 그대로 전달한다', () async {
    final repository = FakeScheduleRepository();
    repository.getMySchedulesResult = const Err(ServerFailure());
    final useCase = GetMySchedulesUseCase(repository);

    final result = await useCase();

    expect(result, isA<Err<List<Schedule>>>());
  });
}
