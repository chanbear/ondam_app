import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/auth/domain/usecases/set_pin_usecase.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SetPinUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = SetPinUseCase(repository);
  });

  test('delegates a valid 4-digit PIN to the repository', () async {
    final result = await useCase('1234');

    expect(result, isA<Ok<void>>());
    expect(repository.setPinCalls, ['1234']);
  });

  test('rejects a PIN that is not exactly 4 digits', () async {
    final result = await useCase('12345');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.setPinCalls, isEmpty);
  });
}
