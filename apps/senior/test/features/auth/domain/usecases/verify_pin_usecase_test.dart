import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/auth/domain/entities/pin_verify_result.dart';
import 'package:ondam_senior/features/auth/domain/usecases/verify_pin_usecase.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late VerifyPinUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = VerifyPinUseCase(repository);
  });

  test('rejects a malformed PIN without calling the repository', () async {
    final result = await useCase('12');

    expect(result, isA<Err<PinVerifyResult>>());
    expect((result as Err<PinVerifyResult>).failure, isA<ValidationFailure>());
    expect(repository.verifyPinCalls, isEmpty);
  });

  test('a correct PIN resolves to Ok(success)', () async {
    repository.verifyPinResult = const Ok(PinVerifyResult.success());

    final result = await useCase('1234');

    expect(result, isA<Ok<PinVerifyResult>>());
    expect((result as Ok<PinVerifyResult>).value.ok, isTrue);
    expect(repository.verifyPinCalls, ['1234']);
  });

  test(
    'a wrong PIN is a domain outcome, not a Failure — carries failedAttempts',
    () async {
      repository.verifyPinResult = const Ok(
        PinVerifyResult.failure(
          reason: PinVerifyFailureReason.wrongPin,
          failedAttempts: 3,
        ),
      );

      final result = await useCase('0000');

      expect(result, isA<Ok<PinVerifyResult>>());
      final value = (result as Ok<PinVerifyResult>).value;
      expect(value.ok, isFalse);
      expect(value.reason, PinVerifyFailureReason.wrongPin);
      expect(value.failedAttempts, 3);
    },
  );

  test('a locked-out PIN carries lockedUntil', () async {
    final lockedUntil = DateTime.utc(2026, 1, 1, 12);
    repository.verifyPinResult = Ok(
      PinVerifyResult.failure(
        reason: PinVerifyFailureReason.locked,
        failedAttempts: 10,
        lockedUntil: lockedUntil,
      ),
    );

    final result = await useCase('0000');

    final value = (result as Ok<PinVerifyResult>).value;
    expect(value.reason, PinVerifyFailureReason.locked);
    expect(value.lockedUntil, lockedUntil);
  });

  test('an expired/invalid session surfaces as a real Failure', () async {
    repository.verifyPinResult = const Err(AuthFailure());

    final result = await useCase('1234');

    expect(result, isA<Err<PinVerifyResult>>());
    expect((result as Err<PinVerifyResult>).failure, isA<AuthFailure>());
  });
}
