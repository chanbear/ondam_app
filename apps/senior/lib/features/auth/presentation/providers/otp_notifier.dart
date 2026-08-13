import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import 'auth_di_providers.dart';

/// Drives the phone-number-OTP step of signup/login/new-device/PIN-forgot
/// re-auth. `state` (`AsyncValue<void>`) is for the widget tree's `.when()`
/// loading/error rendering; each method additionally returns a [Result] so
/// the calling page can decide navigation immediately (riverpod.md: state
/// exposed as AsyncValue, no manual isLoading/error booleans).
class OtpNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns the normalized (E.164) phone number on success, for the page
  /// to pass forward to the OTP-verify screen via route `extra`.
  Future<Result<String>> requestOtp(String rawPhoneNumber) async {
    state = const AsyncLoading();
    final result = await ref
        .read(requestOtpUseCaseProvider)
        .call(rawPhoneNumber);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }

  Future<Result<void>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(verifyOtpUseCaseProvider)
        .call(phoneNumber: phoneNumber, otp: otp);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }
}

final otpNotifierProvider = AsyncNotifierProvider<OtpNotifier, void>(
  OtpNotifier.new,
);
