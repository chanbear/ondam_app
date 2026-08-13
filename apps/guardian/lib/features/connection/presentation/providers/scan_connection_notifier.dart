import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import 'connection_di_providers.dart';

/// QR 스캔 화면에서만 쓰는 상태(riverpod.md autoDispose). `state`가
/// `AsyncLoading`인 동안은 스캔 화면이 추가 스캔 콜백을 무시해야
/// 중복 요청을 막을 수 있다.
class ScanConnectionNotifier extends AsyncNotifier<GuardianLink?> {
  @override
  FutureOr<GuardianLink?> build() => null;

  Future<Result<GuardianLink>> redeem(String token) async {
    state = const AsyncLoading();
    final result = await ref
        .read(redeemConnectionTokenUseCaseProvider)
        .call(token);
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }
}

final scanConnectionProvider =
    AsyncNotifierProvider.autoDispose<ScanConnectionNotifier, GuardianLink?>(
      ScanConnectionNotifier.new,
    );
