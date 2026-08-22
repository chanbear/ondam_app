import 'package:ondam_core/ondam_core.dart';

import '../entities/location_permission_status.dart';
import '../entities/region.dart';

/// Device location capability: permission state + "GPS 좌표 → reverse
/// geocoding → 행정구역" as one call, since every caller in this app wants
/// the readable [Region] right away, never a bare coordinate pair (ONDAM 2.0
/// 요구사항 32). Splitting "get coordinates" and "reverse geocode" into two
/// separate usecases would add a layer nothing in this app currently needs —
/// see `CameraRepository`'s doc comment for the same reasoning applied to
/// camera permission.
abstract class LocationRepository {
  Future<Result<LocationPermissionStatus>> checkPermission();

  Future<Result<LocationPermissionStatus>> requestPermission();

  Future<Result<Region>> getCurrentRegion();
}
