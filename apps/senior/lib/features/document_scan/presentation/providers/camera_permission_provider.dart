import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/camera_permission_status.dart';
import 'document_scan_di_providers.dart';

/// Camera permission state for the entry/camera screens. `build()` checks
/// silently (no OS prompt); [request] triggers the actual prompt.
class CameraPermissionNotifier extends AsyncNotifier<CameraPermissionStatus> {
  @override
  Future<CameraPermissionStatus> build() async {
    final result = await ref.read(checkCameraPermissionUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<void> request() async {
    state = const AsyncLoading();
    final result = await ref
        .read(requestCameraPermissionUseCaseProvider)
        .call();
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final cameraPermissionProvider =
    AsyncNotifierProvider<CameraPermissionNotifier, CameraPermissionStatus>(
      CameraPermissionNotifier.new,
    );
