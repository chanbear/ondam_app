import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/sms_permission_status.dart';
import 'message_check_di_providers.dart';

/// SMS permission state for the entry screen. `build()` checks silently (no
/// OS prompt); [request] triggers the actual prompt. Mirrors
/// `document_scan`'s `CameraPermissionNotifier` pattern.
class SmsPermissionNotifier extends AsyncNotifier<SmsPermissionStatus> {
  @override
  Future<SmsPermissionStatus> build() async {
    final result = await ref.read(checkSmsPermissionUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<void> request() async {
    state = const AsyncLoading();
    final result = await ref.read(requestSmsPermissionUseCaseProvider).call();
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final smsPermissionProvider =
    AsyncNotifierProvider<SmsPermissionNotifier, SmsPermissionStatus>(
      SmsPermissionNotifier.new,
    );
