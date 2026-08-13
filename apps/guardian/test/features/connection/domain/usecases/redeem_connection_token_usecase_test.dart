import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/connection/domain/usecases/redeem_connection_token_usecase.dart';
import 'package:ondam_models/ondam_models.dart';

import '../fakes/fake_connection_repository.dart';

void main() {
  test('빈 토큰은 Repository를 호출하지 않고 ValidationFailure를 반환한다', () async {
    final repository = FakeConnectionRepository();
    final useCase = RedeemConnectionTokenUseCase(repository);

    final result = await useCase('');

    expect(result, isA<Err<GuardianLink>>());
    expect((result as Err<GuardianLink>).failure, isA<ValidationFailure>());
    expect(repository.redeemConnectionTokenCalls, isEmpty);
  });

  test('스캔한 토큰을 Repository에 그대로 전달한다', () async {
    final repository = FakeConnectionRepository();
    final useCase = RedeemConnectionTokenUseCase(repository);

    final result = await useCase('scanned-token');

    expect(result, isA<Ok<GuardianLink>>());
    expect(repository.redeemConnectionTokenCalls, ['scanned-token']);
  });

  test('만료된 토큰 등 Repository 실패를 그대로 전달한다', () async {
    final repository = FakeConnectionRepository();
    repository.redeemConnectionTokenResult = const Err(
      ValidationFailure('QR 코드가 만료됐어요.'),
    );
    final useCase = RedeemConnectionTokenUseCase(repository);

    final result = await useCase('expired-token');

    expect(result, isA<Err<GuardianLink>>());
  });
}
