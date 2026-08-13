import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/connection/domain/usecases/get_guardian_links_usecase.dart';

import '../fakes/fake_connection_repository.dart';

void main() {
  test('연결된 보호자 목록을 Repository에서 그대로 반환한다', () async {
    final repository = FakeConnectionRepository();
    final link = GuardianLink(
      id: 'link-1',
      elderId: 'elder-1',
      guardianId: 'guardian-1',
      status: GuardianLinkStatus.pending,
      createdAt: DateTime.now(),
    );
    repository.getGuardianLinksResult = Ok([link]);
    final useCase = GetGuardianLinksUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<List<GuardianLink>>>());
    expect((result as Ok<List<GuardianLink>>).value, [link]);
  });

  test('빈 목록도 그대로 반환한다', () async {
    final repository = FakeConnectionRepository();
    repository.getGuardianLinksResult = const Ok(<GuardianLink>[]);
    final useCase = GetGuardianLinksUseCase(repository);

    final result = await useCase();

    expect(result, isA<Ok<List<GuardianLink>>>());
    expect((result as Ok<List<GuardianLink>>).value, isEmpty);
  });
}
