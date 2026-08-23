/// 목록 항목 — 어느 공공데이터 소스(지자체/중앙부처)에서 왔는지를
/// `source`로 들고 있어야, 상세조회 시 올바른 업스트림 엔드포인트를 고를
/// 수 있다(`get-benefit-service-detail`이 source별로 다른 엔드포인트를
/// 호출한다).
enum BenefitServiceSource {
  local('local'),
  central('central');

  const BenefitServiceSource(this.value);

  final String value;

  static BenefitServiceSource? fromValue(String? raw) => switch (raw) {
    'local' => BenefitServiceSource.local,
    'central' => BenefitServiceSource.central,
    _ => null,
  };
}

class BenefitService {
  const BenefitService({
    required this.id,
    required this.source,
    required this.title,
    required this.summary,
  });

  final String id;
  final BenefitServiceSource source;
  final String title;
  final String summary;
}
