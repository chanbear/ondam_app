/// A single 경로당/복지센터 search result. [phoneNumber]/[distanceMeters]
/// are nullable — not every real data source provides both (ONDAM 2.0
/// 요구사항 30 §7: "데이터가 제공하는 경우"만 표시).
class SeniorCenter {
  const SeniorCenter({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final double? distanceMeters;
}
