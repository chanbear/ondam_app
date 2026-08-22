import 'package:ondam_core/ondam_core.dart';

import '../../../../core/location/domain/entities/region.dart';
import '../entities/senior_center.dart';

/// 경로당/복지센터 검색 — ONDAM 2.0 요구사항 30. `WelfareCenterRepositoryImpl`
/// 이 공공데이터포털(data.go.kr) "전국마을회관및경로당표준데이터" Open
/// API를 `search-welfare-centers` Edge Function을 통해 호출한다(PHASE 26).
/// 사용자가 아직 data.go.kr 서비스키를 발급받아 Supabase secret으로
/// 등록하지 않았다면 `UnavailableFailure`로 정직하게 안내한다 — 가짜
/// 결과를 만들지 않는다.
abstract class WelfareCenterRepository {
  Future<Result<List<SeniorCenter>>> search(Region region);
}
