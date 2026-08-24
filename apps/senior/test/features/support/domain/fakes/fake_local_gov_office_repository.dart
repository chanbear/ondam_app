import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/support/domain/entities/local_gov_office.dart';
import 'package:ondam_senior/features/support/domain/repositories/local_gov_office_repository.dart';

class FakeLocalGovOfficeRepository implements LocalGovOfficeRepository {
  Result<LocalGovOffice?> searchResult = const Ok(null);

  Region? lastSearchedRegion;
  int searchCalls = 0;

  @override
  Future<Result<LocalGovOffice?>> search(Region region) async {
    searchCalls++;
    lastSearchedRegion = region;
    return searchResult;
  }
}
