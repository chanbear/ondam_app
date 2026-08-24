import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:ondam_guardian/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockScheduleRemoteDataSource extends Mock
    implements ScheduleRemoteDataSource {}

void main() {
  late _MockScheduleRemoteDataSource dataSource;
  late ScheduleRepositoryImpl repository;

  setUp(() {
    dataSource = _MockScheduleRemoteDataSource();
    repository = ScheduleRepositoryImpl(dataSource);
  });

  test('DB row 목록을 Schedule 목록으로 변환해 Ok를 반환한다', () async {
    when(() => dataSource.fetchForElder('elder-1')).thenAnswer(
      (_) async => [
        {
          'id': 's1',
          'elder_id': 'elder-1',
          'title': '병원 방문',
          'scheduled_at': '2026-08-25T10:00:00.000Z',
          'is_recurring': false,
          'completed': false,
          'created_at': '2026-08-24T00:00:00.000Z',
          'recurrence_time': null,
        },
      ],
    );

    final result = await repository.getSchedulesForElder('elder-1');

    expect(result, isA<Ok<List<Schedule>>>());
    final schedules = (result as Ok<List<Schedule>>).value;
    expect(schedules.single.title, '병원 방문');
  });

  test('빈 목록도 에러가 아니라 Ok(빈 리스트)로 반환한다', () async {
    when(() => dataSource.fetchForElder('elder-1')).thenAnswer((_) async => []);

    final result = await repository.getSchedulesForElder('elder-1');

    expect(result, isA<Ok<List<Schedule>>>());
    expect((result as Ok<List<Schedule>>).value, isEmpty);
  });

  test('RLS 위반(연결되지 않은 어르신)은 AuthFailure로 매핑한다', () async {
    when(
      () => dataSource.fetchForElder('elder-1'),
    ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

    final result = await repository.getSchedulesForElder('elder-1');

    expect((result as Err<List<Schedule>>).failure, isA<AuthFailure>());
  });

  test('그 외 PostgrestException은 ServerFailure로 매핑한다', () async {
    when(
      () => dataSource.fetchForElder('elder-1'),
    ).thenThrow(const PostgrestException(message: 'db error', code: '500'));

    final result = await repository.getSchedulesForElder('elder-1');

    expect((result as Err<List<Schedule>>).failure, isA<ServerFailure>());
  });

  test('예상치 못한 예외는 UnknownFailure로 안전하게 처리한다', () async {
    when(
      () => dataSource.fetchForElder('elder-1'),
    ).thenThrow(Exception('boom'));

    final result = await repository.getSchedulesForElder('elder-1');

    expect((result as Err<List<Schedule>>).failure, isA<UnknownFailure>());
  });
}
