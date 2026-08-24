import 'package:ondam_core/ondam_core.dart';

import '../../../../core/location/domain/entities/region.dart';
import '../entities/local_gov_office.dart';

/// 관할 행정기관 연락처 조회 — `LocalGovOfficeRepositoryImpl`이
/// 공공데이터포털(data.go.kr) "읍면동 하부행정기관 현황" 표준데이터를
/// `search-local-government-contact` Edge Function을 통해 호출한다.
/// 일치하는 기관이 없으면(예: 표기가 다른 읍면동) `Ok(null)`을 반환한다 —
/// 오류가 아니라 "찾지 못함"이라는 정직한 결과다. 사용자가 아직 data.go.kr
/// 서비스키를 발급받아 Supabase secret으로 등록하지 않았다면
/// `UnavailableFailure`로 정직하게 안내한다.
abstract class LocalGovOfficeRepository {
  Future<Result<LocalGovOffice?>> search(Region region);
}
