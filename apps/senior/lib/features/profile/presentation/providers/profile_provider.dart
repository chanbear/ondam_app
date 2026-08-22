import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/profile.dart';
import 'profile_di_providers.dart';

/// The elder's saved name/age — same shape as `core/location`'s
/// `RegionNotifier`. `profile_page`가 유일한 구독자라 core가 아니라
/// feature 내부(presentation/providers)에 둔다(architecture.md "특정
/// feature 전용 코드를 core로 올리지 않는다").
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final result = await ref.read(getMyProfileUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Result<void>> save({required String name, required String age}) async {
    final result = await ref
        .read(saveProfileUseCaseProvider)
        .call(name: name, age: age);
    if (result case Ok()) {
      // RegionNotifier.save()와 동일한 이유로 저장 후 재조회한다 — 요청에
      // 쓴 값을 그대로 믿지 않는다.
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);
