import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/region.dart';

/// GPS 좌표 → reverse geocoding → 행정구역 문자열. Both steps run on-device
/// via the platform's own location/geocoder services (Android
/// `Geocoder`/iOS `CLGeocoder` under `geocoding`) — no third-party HTTP API,
/// no API key, no added cost (ONDAM 2.0 요구사항 32 §5/§8 제약). Coordinates
/// never leave this function; only the caller receives the derived [Region]
/// (§9 개인정보 원칙 — 필요 이상으로 정확한 좌표를 저장/전송하지 않는다).
class LocationDataSource {
  Future<Region> getCurrentRegion() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      throw StateError('reverse geocoding returned no placemark');
    }
    final placemark = placemarks.first;

    final sido = placemark.administrativeArea?.trim();
    final sigungu = _firstNonEmpty([
      placemark.subAdministrativeArea,
      placemark.locality,
    ]);
    final dong = _firstNonEmpty([placemark.subLocality, placemark.locality]);

    if (sido == null || sido.isEmpty) {
      throw StateError('reverse geocoding returned no administrative area');
    }

    return Region(sido: sido, sigungu: sigungu ?? '', dong: dong ?? '');
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
