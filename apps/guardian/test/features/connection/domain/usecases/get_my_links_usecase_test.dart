import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/connection/domain/usecases/get_my_links_usecase.dart';
import 'package:ondam_models/ondam_models.dart';

import '../fakes/fake_connection_repository.dart';

void main() {
  test('보호자 본인의 연결 목록을 Repository에서 그대로 반환한다', () async {
    final repository = FakeConnectionRepository();
    final link = GuardianLink(
      id: 'link-1',
      elderId: 'elder-1',
      guardianId: 'guardian-1',
      status: GuardianLinkStatus.accepted,
      createdAt: DateTime.now(),
    );
    repository.getMyLinksResult = Ok([link]);
    final useCase = GetMyLinksUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<List<GuardianLink>>>());
    expect((result as Ok<List<GuardianLink>>).value, [link]);
  });
}
