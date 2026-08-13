import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import 'connection_di_providers.dart';

/// 보호자 측 "어르신 연결 관리" — 이 사용자가 guardian인 모든
/// guardian_links 행(pending/accepted/rejected/revoked)을 담아 UI에서
/// 상태별로 필터링한다.
class MyLinksNotifier extends AsyncNotifier<List<GuardianLink>> {
  @override
  Future<List<GuardianLink>> build() async {
    final result = await ref.read(getMyLinksUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Result<void>> revoke(String linkId) async {
    final result = await ref
        .read(revokeGuardianLinkUseCaseProvider)
        .call(linkId);
    if (result is Ok<void>) {
      ref.invalidateSelf();
    }
    return result;
  }
}

final myLinksProvider =
    AsyncNotifierProvider<MyLinksNotifier, List<GuardianLink>>(
      MyLinksNotifier.new,
    );
