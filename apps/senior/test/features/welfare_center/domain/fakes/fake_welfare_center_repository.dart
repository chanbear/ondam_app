import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/welfare_center/domain/entities/senior_center.dart';
import 'package:ondam_senior/features/welfare_center/domain/repositories/welfare_center_repository.dart';

class FakeWelfareCenterRepository implements WelfareCenterRepository {
  Result<List<SeniorCenter>> searchResult = const Ok([]);

  Region? lastSearchedRegion;
  int searchCalls = 0;

  @override
  Future<Result<List<SeniorCenter>>> search(Region region) async {
    searchCalls++;
    lastSearchedRegion = region;
    return searchResult;
  }
}
