import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/domain/repositories/demographics_repository.dart';

class FakeDemographicsRepository implements DemographicsRepository {
  Result<Demographics?> getMyDemographicsResult = const Ok(null);
  Result<void> saveDemographicsResult = const Ok(null);

  Demographics? savedDemographics;
  int saveCalls = 0;
  int getMyDemographicsCalls = 0;

  @override
  Future<Result<Demographics?>> getMyDemographics() async {
    getMyDemographicsCalls++;
    return getMyDemographicsResult;
  }

  @override
  Future<Result<void>> saveDemographics(Demographics demographics) async {
    saveCalls++;
    savedDemographics = demographics;
    return saveDemographicsResult;
  }
}
