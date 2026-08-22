/// Korea's 17 최상위 광역자치단체 — a fixed, small, well-known list (unlike
/// 시/군/구·읍/면/동, which run into the thousands and aren't bundled in
/// this app). Used to drive the 시/도 picker in the region-input UI.
const List<String> koreaSidoList = [
  '서울특별시',
  '부산광역시',
  '대구광역시',
  '인천광역시',
  '광주광역시',
  '대전광역시',
  '울산광역시',
  '세종특별자치시',
  '경기도',
  '강원특별자치도',
  '충청북도',
  '충청남도',
  '전북특별자치도',
  '전라남도',
  '경상북도',
  '경상남도',
  '제주특별자치도',
];

/// A user's registered area, broken into Korea's administrative tiers so it
/// can later drive a location-based search (`welfare_center`) instead of
/// being a single free-text blob (ONDAM 2.0 요구사항 31). [sigungu]/[dong]
/// are free text today — no canonical dataset of every 시/군/구·읍/면/동 is
/// bundled in this app, so the user (or reverse geocoding) supplies them.
class Region {
  const Region({required this.sido, required this.sigungu, required this.dong});

  final String sido;
  final String sigungu;
  final String dong;

  String get displayName => '$sido $sigungu $dong';

  Region copyWith({String? sido, String? sigungu, String? dong}) {
    return Region(
      sido: sido ?? this.sido,
      sigungu: sigungu ?? this.sigungu,
      dong: dong ?? this.dong,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Region &&
        other.sido == sido &&
        other.sigungu == sigungu &&
        other.dong == dong;
  }

  @override
  int get hashCode => Object.hash(sido, sigungu, dong);
}
