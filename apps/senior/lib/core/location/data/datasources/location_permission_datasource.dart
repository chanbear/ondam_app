import 'package:geolocator/geolocator.dart';

import '../../domain/entities/location_permission_status.dart';

/// Wraps `geolocator`'s own permission API (not `permission_handler`'s) so
/// the permission state it reports always matches what
/// `Geolocator.getCurrentPosition()` will actually do — the only place in
/// this feature allowed to know the `geolocator` package exists, same rule
/// `CameraPermissionDataSource` follows for `permission_handler`.
class LocationPermissionDataSource {
  Future<LocationPermissionStatus> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionStatus.serviceDisabled;
    }
    return _map(await Geolocator.checkPermission());
  }

  Future<LocationPermissionStatus> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionStatus.serviceDisabled;
    }
    return _map(await Geolocator.requestPermission());
  }

  LocationPermissionStatus _map(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.whileInUse ||
      LocationPermission.always => LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.permanentlyDenied,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };
  }
}
