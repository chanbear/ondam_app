import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/connection/domain/usecases/revoke_guardian_link_usecase.dart';

import '../fakes/fake_connection_repository.dart';

void main() {
  test('연결 해제를 Repository에 위임한다', () async {
    final repository = FakeConnectionRepository();
    final useCase = RevokeGuardianLinkUseCase(repository);

    final result = await useCase('link-1');

    expect(result, isA<Ok<void>>());
    expect(repository.revokeLinkCalls, ['link-1']);
  });

  test('Repository 실패를 그대로 전달한다', () async {
    final repository = FakeConnectionRepository();
    repository.revokeLinkResult = const Err(ServerFailure());
    final useCase = RevokeGuardianLinkUseCase(repository);

    final result = await useCase('link-1');

    expect(result, isA<Err<void>>());
  });
}
