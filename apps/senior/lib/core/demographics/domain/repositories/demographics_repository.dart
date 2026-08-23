import 'package:ondam_core/ondam_core.dart';

import '../entities/demographics.dart';

/// 어르신의 나이/성별 — 저장 전까지는 `null`(또는 `Demographics`의 일부
/// 필드가 `null`)이 정직한 "미입력" 상태다(`RegionRepository`와 동일한
/// 원칙).
abstract class DemographicsRepository {
  Future<Result<Demographics?>> getMyDemographics();

  Future<Result<void>> saveDemographics(Demographics demographics);
}
