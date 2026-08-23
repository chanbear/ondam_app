import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/domain/repositories/benefit_service_repository.dart';

class FakeBenefitServiceRepository implements BenefitServiceRepository {
  Result<List<BenefitService>> searchResult = const Ok([]);
  Result<BenefitServiceDetail> getDetailResult = const Err(UnknownFailure());

  Demographics? lastSearchedDemographics;
  Region? lastSearchedRegion;
  int searchCalls = 0;

  String? lastDetailId;
  BenefitServiceSource? lastDetailSource;
  int getDetailCalls = 0;

  @override
  Future<Result<List<BenefitService>>> search(
    Demographics demographics,
    Region region,
  ) async {
    searchCalls++;
    lastSearchedDemographics = demographics;
    lastSearchedRegion = region;
    return searchResult;
  }

  @override
  Future<Result<BenefitServiceDetail>> getDetail(
    String id,
    BenefitServiceSource source,
  ) async {
    getDetailCalls++;
    lastDetailId = id;
    lastDetailSource = source;
    return getDetailResult;
  }
}
