import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/domain/usecases/invalidate_fcm_token_usecase.dart';
import 'package:ondam_guardian/features/notification/domain/usecases/register_fcm_token_usecase.dart';

import '../fakes/fake_fcm_token_repository.dart';

void main() {
  group('RegisterFcmTokenUseCase', () {
    test('token/deviceInfo를 Repository에 그대로 전달한다', () async {
      final repository = FakeFcmTokenRepository();
      final useCase = RegisterFcmTokenUseCase(repository);

      await useCase(
        token: 'token-1',
        deviceInfo: const <String, dynamic>{'platform': 'android'},
      );

      expect(repository.registerTokenCalls, [
        (
          token: 'token-1',
          deviceInfo: const <String, dynamic>{'platform': 'android'},
        ),
      ]);
    });

    test('Repository 실패를 그대로 전달한다', () async {
      final repository = FakeFcmTokenRepository();
      repository.registerTokenResult = const Err(ServerFailure());
      final useCase = RegisterFcmTokenUseCase(repository);

      final result = await useCase(token: 'token-1', deviceInfo: const {});

      expect(result, isA<Err<void>>());
    });
  });

  group('InvalidateFcmTokenUseCase', () {
    test('token을 Repository에 그대로 전달한다', () async {
      final repository = FakeFcmTokenRepository();
      final useCase = InvalidateFcmTokenUseCase(repository);

      await useCase('token-1');

      expect(repository.invalidateTokenCalls, ['token-1']);
    });

    test('Repository 실패를 그대로 전달한다', () async {
      final repository = FakeFcmTokenRepository();
      repository.invalidateTokenResult = const Err(ServerFailure());
      final useCase = InvalidateFcmTokenUseCase(repository);

      final result = await useCase('token-1');

      expect(result, isA<Err<void>>());
    });
  });
}
