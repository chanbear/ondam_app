import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/domain/repositories/region_repository.dart';

class FakeRegionRepository implements RegionRepository {
  Result<Region?> getMyRegionResult = const Ok(null);
  Result<void> saveRegionResult = const Ok(null);

  Region? savedRegion;
  int saveCalls = 0;
  int getMyRegionCalls = 0;

  @override
  Future<Result<Region?>> getMyRegion() async {
    getMyRegionCalls++;
    return getMyRegionResult;
  }

  @override
  Future<Result<void>> saveRegion(Region region) async {
    saveCalls++;
    savedRegion = region;
    return saveRegionResult;
  }
}
