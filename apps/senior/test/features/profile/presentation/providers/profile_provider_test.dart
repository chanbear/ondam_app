import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/profile/domain/entities/profile.dart';
import 'package:ondam_senior/features/profile/presentation/providers/profile_di_providers.dart';
import 'package:ondam_senior/features/profile/presentation/providers/profile_provider.dart';

import '../../domain/fakes/fake_profile_repository.dart';

void main() {
  test('저장 성공 후에는 요청 값을 그대로 믿지 않고 서버에서 다시 조회한다(저장 후 재조회)', () async {
    final repository = FakeProfileRepository();
    repository.getMyProfileResult = const Ok(null);
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(profileProvider.future);
    expect(repository.getMyProfileCalls, 1);

    const profile = Profile(name: '홍길동', age: 73);
    repository.getMyProfileResult = const Ok(profile);

    final result = await container
        .read(profileProvider.notifier)
        .save(name: '홍길동', age: '73');

    expect(result, isA<Ok<void>>());
    expect(repository.saveCalls, 1);
    expect(repository.getMyProfileCalls, greaterThanOrEqualTo(2));
    expect(container.read(profileProvider).value?.name, '홍길동');
    expect(container.read(profileProvider).value?.age, 73);
  });

  test('저장 실패 시에는 재조회하지 않는다', () async {
    final repository = FakeProfileRepository();
    repository.getMyProfileResult = const Ok(null);
    repository.saveProfileResult = const Err(ServerFailure());
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(profileProvider.future);
    final callsAfterInitialLoad = repository.getMyProfileCalls;

    final result = await container
        .read(profileProvider.notifier)
        .save(name: '홍길동', age: '73');

    expect(result, isA<Err<void>>());
    expect(repository.getMyProfileCalls, callsAfterInitialLoad);
  });
}
