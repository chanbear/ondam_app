import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/emergency_help/domain/usecases/get_guardian_phone_usecase.dart';

import '../fakes/fake_guardian_contact_repository.dart';

void main() {
  test('연결된 보호자 번호를 Repository에서 그대로 반환한다', () async {
    final repository = FakeGuardianContactRepository()
      ..result = const Ok('+821012345678');
    final useCase = GetGuardianPhoneUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<String?>>());
    expect((result as Ok<String?>).value, '+821012345678');
  });

  test('연결된 보호자가 없으면 null을 그대로 반환한다', () async {
    final repository = FakeGuardianContactRepository();
    final useCase = GetGuardianPhoneUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<String?>>());
    expect((result as Ok<String?>).value, isNull);
  });

  test('repository가 실패를 반환하면 그대로 전달한다', () async {
    final repository = FakeGuardianContactRepository()
      ..result = const Err(ServerFailure());
    final useCase = GetGuardianPhoneUseCase(repository);

    final result = await useCase();

    expect(result, isA<Err<String?>>());
    expect((result as Err<String?>).failure, isA<ServerFailure>());
  });
}
