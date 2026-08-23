import 'package:ondam_core/ondam_core.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../entities/benefit_service.dart';
import '../entities/benefit_service_detail.dart';

/// 나이/성별/지역 기반 맞춤 혜택 정보 검색 — `search-benefit-services`/
/// `get-benefit-service-detail` Edge Function을 호출한다. 데이터 소스가
/// 아직 설정되지 않았으면(서비스키 미등록) `UnavailableFailure`로 정직하게
/// 안내한다(`WelfareCenterRepository`와 동일한 원칙).
abstract class BenefitServiceRepository {
  Future<Result<List<BenefitService>>> search(
    Demographics demographics,
    Region region,
  );

  Future<Result<BenefitServiceDetail>> getDetail(
    String id,
    BenefitServiceSource source,
  );
}
