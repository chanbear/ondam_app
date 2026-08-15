import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/mic_permission_status.dart';
import 'voice_assistant_di_providers.dart';

/// Mic permission state for the voice assistant entry screen. `build()`
/// checks silently (no OS prompt); [request] triggers the actual prompt.
/// Mirrors `document_scan`'s `CameraPermissionNotifier`.
class MicPermissionNotifier extends AsyncNotifier<MicPermissionStatus> {
  @override
  Future<MicPermissionStatus> build() async {
    final result = await ref.read(checkMicPermissionUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<void> request() async {
    state = const AsyncLoading();
    final result = await ref.read(requestMicPermissionUseCaseProvider).call();
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final micPermissionProvider =
    AsyncNotifierProvider<MicPermissionNotifier, MicPermissionStatus>(
      MicPermissionNotifier.new,
    );
