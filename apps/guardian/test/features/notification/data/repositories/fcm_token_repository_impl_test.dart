import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/data/datasources/fcm_token_remote_datasource.dart';
import 'package:ondam_guardian/features/notification/data/repositories/fcm_token_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockFcmTokenRemoteDataSource extends Mock
    implements FcmTokenRemoteDataSource {}

void main() {
  late _MockFcmTokenRemoteDataSource dataSource;
  late FcmTokenRepositoryImpl repository;

  setUp(() {
    dataSource = _MockFcmTokenRemoteDataSource();
    repository = FcmTokenRepositoryImpl(dataSource);
  });

  group('invalidateToken', () {
    test('본인 token이 실제로 삭제되면(delete().select()가 행을 반환) Ok를 돌려준다', () async {
      when(
        () => dataSource.deleteToken('my-device-token'),
      ).thenAnswer((_) async => true);

      final result = await repository.invalidateToken('my-device-token');

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.deleteToken('my-device-token')).called(1);
    });

    test('다른 사용자의 token이라 RLS가 막아 0건 삭제되면(false) ValidationFailure를 반환한다 — '
        '성공으로 오인하지 않는다', () async {
      when(
        () => dataSource.deleteToken('someone-elses-token'),
      ).thenAnswer((_) async => false);

      final result = await repository.invalidateToken('someone-elses-token');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
    });

    test('PostgrestException은 ServerFailure/AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.deleteToken('my-device-token'),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

      final result = await repository.invalidateToken('my-device-token');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<AuthFailure>());
    });
  });
}
