import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/auth/pin_verified_provider.dart';
import '../../domain/entities/pin_verify_result.dart';
import 'auth_di_providers.dart';
import 'has_pin_provider.dart';

/// Drives PIN setup/verify/reset. On a successful [verifyPin] or
/// [setPin]/[resetPin], marks `pinVerifiedProvider` true — this is the one
/// place in the app allowed to do that (riverpod.md: business logic behind
/// a Notifier method, not inside a widget's `build()`).
class PinNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> setPin(String pin) async {
    state = const AsyncLoading();
    final result = await ref.read(setPinUseCaseProvider).call(pin);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    if (result is Ok<void>) {
      ref.read(pinVerifiedProvider.notifier).markVerified();
      ref.invalidate(hasPinProvider);
    }
    return result;
  }

  Future<Result<PinVerifyResult>> verifyPin(String pin) async {
    state = const AsyncLoading();
    final result = await ref.read(verifyPinUseCaseProvider).call(pin);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    if (result case Ok(value: final verifyResult) when verifyResult.ok) {
      ref.read(pinVerifiedProvider.notifier).markVerified();
    }
    return result;
  }

  Future<Result<void>> resetPin(String pin) async {
    state = const AsyncLoading();
    final result = await ref.read(resetPinUseCaseProvider).call(pin);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    if (result is Ok<void>) {
      ref.read(pinVerifiedProvider.notifier).markVerified();
      ref.invalidate(hasPinProvider);
    }
    return result;
  }

  Future<Result<void>> deleteAccount() async {
    state = const AsyncLoading();
    final result = await ref.read(deleteAccountUseCaseProvider).call();
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    if (result is Ok<void>) {
      ref.read(pinVerifiedProvider.notifier).reset();
    }
    return result;
  }
}

final pinNotifierProvider = AsyncNotifierProvider<PinNotifier, void>(
  PinNotifier.new,
);
