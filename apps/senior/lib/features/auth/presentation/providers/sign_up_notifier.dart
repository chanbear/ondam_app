import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import 'auth_di_providers.dart';

/// Drives the phone-number signup/login step (no OTP — see
/// technical-decisions.md §1-3-A "OTP 제거") and the silent re-signin the
/// PIN-forgot flow performs before resetting a PIN. `state`
/// (`AsyncValue<void>`) is for the widget tree's `.when()` loading/error
/// rendering; [signUp] additionally returns a [Result] so the calling page
/// can react immediately (riverpod.md: state exposed as AsyncValue, no
/// manual isLoading/error booleans).
class SignUpNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> signUp({
    required String name,
    required String rawPhoneNumber,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signUpUseCaseProvider)
        .call(name: name, rawPhoneNumber: rawPhoneNumber);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }
}

final signUpNotifierProvider = AsyncNotifierProvider<SignUpNotifier, void>(
  SignUpNotifier.new,
);
