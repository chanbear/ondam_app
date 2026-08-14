import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:ondam_guardian/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockNotificationRemoteDataSource extends Mock
    implements NotificationRemoteDataSource {}

void main() {
  late _MockNotificationRemoteDataSource dataSource;
  late NotificationRepositoryImpl repository;

  setUp(() {
    dataSource = _MockNotificationRemoteDataSource();
    repository = NotificationRepositoryImpl(dataSource);
  });

  group('markAsRead', () {
    test(
      '본인 소유 알림이면 mark_notification_read RPC가 true를 반환하고 Ok를 돌려준다',
      () async {
        when(() => dataSource.markRead('note-1')).thenAnswer((_) async => true);

        final result = await repository.markAsRead('note-1');

        expect(result, isA<Ok<void>>());
        verify(() => dataSource.markRead('note-1')).called(1);
      },
    );

    test('존재하지 않거나 다른 사용자의 알림이면(RPC가 false) ValidationFailure를 반환한다 — '
        '성공으로 오인하지 않는다', () async {
      when(
        () => dataSource.markRead('someone-elses-note'),
      ).thenAnswer((_) async => false);

      final result = await repository.markAsRead('someone-elses-note');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
    });

    test('PostgrestException은 ServerFailure/AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.markRead('note-1'),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

      final result = await repository.markAsRead('note-1');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<AuthFailure>());
    });
  });
}
