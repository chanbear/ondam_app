import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:ondam_senior/features/schedule/data/repositories/schedule_repository_impl.dart';
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

  group('getMySchedules', () {
    test('DB row 목록을 Schedule 목록으로 변환해 Ok를 반환한다', () async {
      when(() => dataSource.fetchMine()).thenAnswer(
        (_) async => [
          {
            'id': 's1',
            'elder_id': 'e1',
            'title': '병원 방문',
            'scheduled_at': '2026-08-25T10:00:00.000Z',
            'is_recurring': false,
            'completed': false,
            'created_at': '2026-08-24T00:00:00.000Z',
            'recurrence_time': null,
          },
        ],
      );

      final result = await repository.getMySchedules();

      expect(result, isA<Ok<List<Schedule>>>());
      final schedules = (result as Ok<List<Schedule>>).value;
      expect(schedules.single.title, '병원 방문');
    });

    test('빈 목록도 에러가 아니라 Ok(빈 리스트)로 반환한다', () async {
      when(() => dataSource.fetchMine()).thenAnswer((_) async => []);

      final result = await repository.getMySchedules();

      expect(result, isA<Ok<List<Schedule>>>());
      expect((result as Ok<List<Schedule>>).value, isEmpty);
    });

    test('로그인되어 있지 않으면(AuthException) AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenThrow(const AuthException('로그인이 필요해요.'));

      final result = await repository.getMySchedules();

      expect((result as Err<List<Schedule>>).failure, isA<AuthFailure>());
    });

    test('RLS 위반(PostgrestException 42501)은 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

      final result = await repository.getMySchedules();

      expect((result as Err<List<Schedule>>).failure, isA<AuthFailure>());
    });

    test('그 외 PostgrestException은 ServerFailure로 매핑한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenThrow(const PostgrestException(message: 'db error', code: '500'));

      final result = await repository.getMySchedules();

      expect((result as Err<List<Schedule>>).failure, isA<ServerFailure>());
    });

    test('예상치 못한 예외는 UnknownFailure로 안전하게 처리한다', () async {
      when(() => dataSource.fetchMine()).thenThrow(Exception('boom'));

      final result = await repository.getMySchedules();

      expect((result as Err<List<Schedule>>).failure, isA<UnknownFailure>());
    });
  });

  group('createSchedule', () {
    test('성공하면 Ok를 반환한다', () async {
      when(
        () => dataSource.create(
          title: any(named: 'title'),
          scheduledAt: any(named: 'scheduledAt'),
          isRecurring: any(named: 'isRecurring'),
          recurrenceHour: any(named: 'recurrenceHour'),
          recurrenceMinute: any(named: 'recurrenceMinute'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.createSchedule(
        title: '병원 방문',
        scheduledAt: DateTime(2026, 8, 25, 10, 0),
        isRecurring: false,
      );

      expect(result, isA<Ok<void>>());
    });

    test('예상치 못한 예외는 UnknownFailure로 처리한다', () async {
      when(
        () => dataSource.create(
          title: any(named: 'title'),
          scheduledAt: any(named: 'scheduledAt'),
          isRecurring: any(named: 'isRecurring'),
          recurrenceHour: any(named: 'recurrenceHour'),
          recurrenceMinute: any(named: 'recurrenceMinute'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await repository.createSchedule(
        title: '병원 방문',
        scheduledAt: DateTime(2026, 8, 25, 10, 0),
        isRecurring: false,
      );

      expect((result as Err<void>).failure, isA<UnknownFailure>());
    });
  });

  group('toggleCompleted', () {
    test('성공하면 Ok를 반환한다', () async {
      when(
        () => dataSource.toggleCompleted('s1', true),
      ).thenAnswer((_) async {});

      final result = await repository.toggleCompleted('s1', true);

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.toggleCompleted('s1', true)).called(1);
    });

    test('RLS 위반(다른 사람의 일정)은 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.toggleCompleted('other', true),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

      final result = await repository.toggleCompleted('other', true);

      expect((result as Err<void>).failure, isA<AuthFailure>());
    });
  });

  group('deleteSchedule', () {
    test('성공하면 Ok를 반환한다', () async {
      when(() => dataSource.delete('s1')).thenAnswer((_) async {});

      final result = await repository.deleteSchedule('s1');

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.delete('s1')).called(1);
    });

    test('예상치 못한 예외는 UnknownFailure로 처리한다', () async {
      when(() => dataSource.delete('s1')).thenThrow(Exception('boom'));

      final result = await repository.deleteSchedule('s1');

      expect((result as Err<void>).failure, isA<UnknownFailure>());
    });
  });
}
