import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/connection/domain/usecases/respond_to_connection_request_usecase.dart';

import '../fakes/fake_connection_repository.dart';

void main() {
  test('수락 요청을 accept=true로 Repository에 전달한다', () async {
    final repository = FakeConnectionRepository();
    final useCase = RespondToConnectionRequestUseCase(repository);

    final result = await useCase(linkId: 'link-1', accept: true);

    expect(result, isA<Ok<void>>());
    expect(repository.respondToRequestCalls, [
      (linkId: 'link-1', accept: true),
    ]);
  });

  test('거절 요청을 accept=false로 Repository에 전달한다', () async {
    final repository = FakeConnectionRepository();
    final useCase = RespondToConnectionRequestUseCase(repository);

    final result = await useCase(linkId: 'link-2', accept: false);

    expect(result, isA<Ok<void>>());
    expect(repository.respondToRequestCalls, [
      (linkId: 'link-2', accept: false),
    ]);
  });
}
