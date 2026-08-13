import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/auth/domain/usecases/reset_pin_usecase.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ResetPinUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = ResetPinUseCase(repository);
  });

  test('delegates a valid new PIN to the repository', () async {
    final result = await useCase('4321');

    expect(result, isA<Ok<void>>());
    expect(repository.resetPinCalls, ['4321']);
  });

  test('rejects a non-numeric PIN without calling the repository', () async {
    final result = await useCase('12a4');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.resetPinCalls, isEmpty);
  });

  test(
    'propagates a reauthentication_required failure from the server',
    () async {
      repository.resetPinResult = const Err(AuthFailure());

      final result = await useCase('4321');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<AuthFailure>());
    },
  );
}
