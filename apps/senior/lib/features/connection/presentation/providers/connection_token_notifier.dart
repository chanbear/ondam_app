import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/connection_token.dart';
import 'connection_di_providers.dart';

/// QR 표시 화면에서만 쓰는 상태 — 화면을 벗어나면 폐기(riverpod.md
/// "화면 하나에서만 쓰는 상태는... autoDispose를 사용"). 토큰은 서버에서
/// 5분짜리로 발급되므로(technical-decisions.md §1-6 v9), 화면이 계속 열려
/// 있어도 자동 재발급은 하지 않고 `regenerate()`를 명시적으로 호출해야
/// 한다 — 화면 쪽(QR 표시 페이지)이 만료 타이머를 보고 판단한다.
class ConnectionTokenNotifier extends AsyncNotifier<ConnectionToken> {
  @override
  Future<ConnectionToken> build() async {
    final result = await ref
        .read(generateConnectionTokenUseCaseProvider)
        .call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  void regenerate() => ref.invalidateSelf();
}

final connectionTokenProvider =
    AsyncNotifierProvider.autoDispose<ConnectionTokenNotifier, ConnectionToken>(
      ConnectionTokenNotifier.new,
    );
