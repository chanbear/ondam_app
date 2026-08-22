import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/location_permission_status.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/domain/repositories/location_repository.dart';

class FakeLocationRepository implements LocationRepository {
  Result<LocationPermissionStatus> checkResult = const Ok(
    LocationPermissionStatus.denied,
  );
  Result<LocationPermissionStatus> requestResult = const Ok(
    LocationPermissionStatus.granted,
  );
  Result<Region> currentRegionResult = const Ok(
    Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
  );

  int checkCalls = 0;
  int requestCalls = 0;
  int getCurrentRegionCalls = 0;

  @override
  Future<Result<LocationPermissionStatus>> checkPermission() async {
    checkCalls++;
    return checkResult;
  }

  @override
  Future<Result<LocationPermissionStatus>> requestPermission() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<Result<Region>> getCurrentRegion() async {
    getCurrentRegionCalls++;
    return currentRegionResult;
  }
}
