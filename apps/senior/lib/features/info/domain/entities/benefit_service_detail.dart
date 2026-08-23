/// 상세 화면 전용 엔티티 — 목록 API가 반환하지 않는 필드(지원대상/
/// 신청방법/문의처/외부 링크)를 담는다. 업스트림 API가 해당 필드를 주지
/// 않으면 `null`(정직한 "제공하지 않음")이지, 빈 문자열을 지어내지 않는다.
class BenefitServiceDetail {
  const BenefitServiceDetail({
    required this.id,
    required this.title,
    required this.summary,
    this.supportTarget,
    this.applyMethod,
    this.contact,
    this.externalUrl,
  });

  final String id;
  final String title;
  final String summary;
  final String? supportTarget;
  final String? applyMethod;
  final String? contact;
  final String? externalUrl;
}
