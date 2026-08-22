import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/auth/domain/usecases/sign_up_usecase.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SignUpUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = SignUpUseCase(repository);
  });

  test(
    'normalizes a valid phone number and delegates to the repository',
    () async {
      final result = await useCase(
        name: '홍길동',
        rawPhoneNumber: '010-1234-5678',
      );

      expect(result, isA<Ok<void>>());
      expect(repository.signUpCalls, [
        (name: '홍길동', phoneNumber: '+821012345678'),
      ]);
    },
  );

  test('trims the name before delegating', () async {
    await useCase(name: '  홍길동  ', rawPhoneNumber: '010-1234-5678');

    expect(repository.signUpCalls.single.name, '홍길동');
  });

  test('rejects an empty name without calling the repository', () async {
    final result = await useCase(name: '  ', rawPhoneNumber: '010-1234-5678');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.signUpCalls, isEmpty);
  });

  test(
    'rejects an invalid phone number without calling the repository',
    () async {
      final result = await useCase(name: '홍길동', rawPhoneNumber: '123');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.signUpCalls, isEmpty);
    },
  );

  test('propagates a repository failure', () async {
    repository.signUpResult = const Err(NetworkFailure());

    final result = await useCase(name: '홍길동', rawPhoneNumber: '010-1234-5678');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<NetworkFailure>());
  });
}
