import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/connection/domain/entities/connection_token.dart';
import 'package:ondam_senior/features/connection/domain/usecases/generate_connection_token_usecase.dart';

import '../fakes/fake_connection_repository.dart';

void main() {
  test('QR 표시용 토큰 발급을 Repository에 위임한다', () async {
    final repository = FakeConnectionRepository();
    final token = ConnectionToken(
      token: 'abc',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    repository.generateConnectionTokenResult = Ok(token);
    final useCase = GenerateConnectionTokenUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<ConnectionToken>>());
    expect((result as Ok<ConnectionToken>).value.token, 'abc');
  });

  test('Repository 실패를 그대로 전달한다', () async {
    final repository = FakeConnectionRepository();
    repository.generateConnectionTokenResult = const Err(NetworkFailure());
    final useCase = GenerateConnectionTokenUseCase(repository);

    final result = await useCase();

    expect(result, isA<Err<ConnectionToken>>());
  });
}
