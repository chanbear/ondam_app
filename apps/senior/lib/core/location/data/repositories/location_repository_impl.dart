import 'dart:async';

import 'package:geolocator/geolocator.dart'
    show LocationServiceDisabledException, PermissionDeniedException;
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/location_permission_status.dart';
import '../../domain/entities/region.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';
import '../datasources/location_permission_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(
    this._permissionDataSource,
    this._locationDataSource,
  );

  final LocationPermissionDataSource _permissionDataSource;
  final LocationDataSource _locationDataSource;

  @override
  Future<Result<LocationPermissionStatus>> checkPermission() async {
    try {
      return Ok(await _permissionDataSource.check());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<LocationPermissionStatus>> requestPermission() async {
    try {
      return Ok(await _permissionDataSource.request());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<Region>> getCurrentRegion() async {
    try {
      return Ok(await _locationDataSource.getCurrentRegion());
    } on LocationServiceDisabledException {
      return const Err(LocationFailure('위치 서비스가 꺼져 있어요. 설정에서 켜주세요.'));
    } on PermissionDeniedException {
      return const Err(LocationFailure('위치 권한을 허용해주세요.'));
    } on TimeoutException {
      return const Err(LocationFailure('현재 위치를 확인하지 못했어요. 다시 시도해주세요.'));
    } on StateError {
      // reverse geocoding이 결과를 못 찾은 경우(§8 데이터소스 미확정 지역 등).
      return const Err(LocationFailure('현재 위치를 지역명으로 바꾸지 못했어요.'));
    } catch (_) {
      return const Err(LocationFailure());
    }
  }
}
