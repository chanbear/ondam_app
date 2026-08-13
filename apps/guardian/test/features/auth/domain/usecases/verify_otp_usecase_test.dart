import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/auth/domain/usecases/verify_otp_usecase.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late VerifyOtpUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = VerifyOtpUseCase(repository);
  });

  test('delegates a valid 6-digit code to the repository', () async {
    final result = await useCase(phoneNumber: '+821012345678', otp: '123456');

    expect(result, isA<Ok<void>>());
    expect(repository.verifyOtpCalls, [
      (phoneNumber: '+821012345678', otp: '123456'),
    ]);
  });

  test('rejects a malformed code without calling the repository', () async {
    final result = await useCase(phoneNumber: '+821012345678', otp: '12a456');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.verifyOtpCalls, isEmpty);
  });
}
