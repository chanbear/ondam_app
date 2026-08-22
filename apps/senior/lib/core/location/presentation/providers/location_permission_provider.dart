import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/location_permission_status.dart';
import 'location_di_providers.dart';

/// Location permission state for the region-input screen. `build()` checks
/// silently (no OS prompt); [request] triggers the actual prompt — mirrors
/// `CameraPermissionNotifier`.
class LocationPermissionNotifier
    extends AsyncNotifier<LocationPermissionStatus> {
  @override
  Future<LocationPermissionStatus> build() async {
    final result = await ref
        .read(checkLocationPermissionUseCaseProvider)
        .call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<void> request() async {
    state = const AsyncLoading();
    final result = await ref
        .read(requestLocationPermissionUseCaseProvider)
        .call();
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final locationPermissionProvider =
    AsyncNotifierProvider<LocationPermissionNotifier, LocationPermissionStatus>(
      LocationPermissionNotifier.new,
    );
