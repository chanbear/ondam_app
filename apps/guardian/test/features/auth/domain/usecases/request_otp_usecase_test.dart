import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/auth/domain/usecases/request_otp_usecase.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late RequestOtpUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = RequestOtpUseCase(repository);
  });

  test(
    'normalizes a valid phone number and delegates to the repository',
    () async {
      final result = await useCase('010-1234-5678');

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, '+821012345678');
      expect(repository.requestOtpCalls, ['+821012345678']);
    },
  );

  test(
    'rejects an invalid phone number without calling the repository',
    () async {
      final result = await useCase('123');

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).failure, isA<ValidationFailure>());
      expect(repository.requestOtpCalls, isEmpty);
    },
  );

  test('propagates a repository failure', () async {
    repository.requestOtpResult = const Err(NetworkFailure());

    final result = await useCase('010-1234-5678');

    expect(result, isA<Err<String>>());
    expect((result as Err<String>).failure, isA<NetworkFailure>());
  });
}
