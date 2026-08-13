import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import 'connection_di_providers.dart';

/// 어르신 측 "연결된 보호자 목록" — pending/accepted/rejected/revoked 전체를
/// 담아 UI에서 상태별로 필터링한다.
class GuardianLinksNotifier extends AsyncNotifier<List<GuardianLink>> {
  @override
  Future<List<GuardianLink>> build() async {
    final result = await ref.read(getGuardianLinksUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Result<void>> respond({
    required String linkId,
    required bool accept,
  }) async {
    final result = await ref
        .read(respondToConnectionRequestUseCaseProvider)
        .call(linkId: linkId, accept: accept);
    if (result is Ok<void>) {
      ref.invalidateSelf();
    }
    return result;
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

final guardianLinksProvider =
    AsyncNotifierProvider<GuardianLinksNotifier, List<GuardianLink>>(
      GuardianLinksNotifier.new,
    );
