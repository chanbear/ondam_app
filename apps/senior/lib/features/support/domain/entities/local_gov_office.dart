/// 어르신이 등록한 지역의 관할 시청/군청/구청 또는 동 주민센터(행정복지센터)
/// 연락처. [phoneNumber]는 nullable — 현재 연결된 데이터 소스(행정안전부
/// "읍면동 하부행정기관 현황" 표준데이터, data.go.kr dataset id 15059715)는
/// 시도/시군구/읍면동/우편번호/주소만 제공하고 전화번호·기관명 컬럼이 없다
/// (2026-08-23 data.go.kr 공식 필드 목록 확인). 다른 데이터 소스가 연결되기
/// 전까지 [phoneNumber]는 항상 null이다 — 가짜 번호를 채우지 않는다.
class LocalGovOffice {
  const LocalGovOffice({
    required this.address,
    this.postalCode,
    this.phoneNumber,
  });

  final String address;
  final String? postalCode;
  final String? phoneNumber;
}
