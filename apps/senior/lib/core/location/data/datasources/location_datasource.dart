import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../app/config/app_config.dart';
import '../../domain/entities/region.dart';

/// GPS 좌표 → reverse geocoding → 행정구역 문자열. 네이티브 플랫폼은 기기
/// 자체 geocoder(Android `Geocoder`/iOS `CLGeocoder`, `geocoding` 패키지)를
/// 쓴다 — 제3자 HTTP API도, API 키도, 추가 비용도 없다(ONDAM 2.0 요구사항
/// 32 §5/§8 제약). `geocoding`은 웹 구현체가 없어서 웹에서만 예외적으로
/// 카카오 로컬 API(REST)를 쓴다. 두 경로 모두 좌표는 이 함수 밖으로 나가지
/// 않고, 파생된 [Region]만 호출자에게 전달한다(§9 개인정보 원칙).
class LocationDataSource {
  Future<Region> getCurrentRegion() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );

    if (kIsWeb) {
      return _reverseGeocodeWeb(position.latitude, position.longitude);
    }

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

  Future<Region> _reverseGeocodeWeb(double latitude, double longitude) async {
    final uri = Uri.https(
      'dapi.kakao.com',
      '/v2/local/geo/coord2regioncode.json',
      {'x': longitude.toString(), 'y': latitude.toString()},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'KakaoAK ${AppConfig.kakaoRestApiKey}'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Kakao reverse geocoding failed: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = (body['documents'] as List).cast<Map<String, dynamic>>();
    if (documents.isEmpty) {
      throw StateError('reverse geocoding returned no placemark');
    }
    // "H"(행정동)를 우선한다 — 없으면 "B"(법정동)로 대체.
    final doc = documents.firstWhere(
      (d) => d['region_type'] == 'H',
      orElse: () => documents.first,
    );

    final sido = (doc['region_1depth_name'] as String? ?? '').trim();
    final sigungu = (doc['region_2depth_name'] as String? ?? '').trim();
    final dong = (doc['region_3depth_name'] as String? ?? '').trim();
    if (sido.isEmpty) {
      throw StateError('reverse geocoding returned no administrative area');
    }

    return Region(sido: sido, sigungu: sigungu, dong: dong);
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
