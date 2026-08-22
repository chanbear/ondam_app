/// What kind of date this is — closed set matching the categories ONDAM 2.0
/// cares about (납부 기한/방문 날짜/신청 기간/만료일/예약 날짜/기타).
enum ImportantDateKind {
  paymentDue,
  visit,
  applicationPeriod,
  expiration,
  reservation,
  other;

  /// JSON wire value only — no DB column backs this yet (Phase 3 판단:
  /// 새 migration 없이 준비만 함). Do not confuse with the `toDbValue()`
  /// pattern other enums here use for an actual `check` constraint.
  String toWireValue() => name;

  static ImportantDateKind fromWireValue(String value) => switch (value) {
    'paymentDue' => ImportantDateKind.paymentDue,
    'visit' => ImportantDateKind.visit,
    'applicationPeriod' => ImportantDateKind.applicationPeriod,
    'expiration' => ImportantDateKind.expiration,
    'reservation' => ImportantDateKind.reservation,
    'other' => ImportantDateKind.other,
    _ => throw ArgumentError('Unknown ImportantDate.kind: $value'),
  };
}

/// How urgently the user should notice this date — independent of
/// [ReliabilityLevel]/[RiskLevel], same "서로 다른 축" principle.
enum ImportantDatePriority {
  high,
  medium,
  low;

  String toWireValue() => name;

  static ImportantDatePriority fromWireValue(String value) => switch (value) {
    'high' => ImportantDatePriority.high,
    'medium' => ImportantDatePriority.medium,
    'low' => ImportantDatePriority.low,
    _ => throw ArgumentError('Unknown ImportantDate.priority: $value'),
  };
}

/// A single important date extracted from a document/message (마감일, 방문일
/// 등). [needsSourceEvidence]는 이 날짜가 원문 근거와 함께 표시돼야 하는지를
/// 나타내는 플래그일 뿐 — 실제 원문 발췌 텍스트는 담지 않는다(과도한 설계
/// 방지, Phase 3 지시). 날짜 추출/파싱 로직 자체는 이번 Phase의 범위가
/// 아니다 — 이 클래스는 "담을 수 있는 그릇"만 정의한다.
class ImportantDate {
  const ImportantDate({
    required this.date,
    required this.kind,
    this.label,
    this.priority = ImportantDatePriority.medium,
    this.needsSourceEvidence = false,
  });

  final DateTime date;
  final ImportantDateKind kind;

  /// 표시용 자유 텍스트 (예: "전기요금 납부기한"). 없으면 UI가 [kind]로부터
  /// 기본 라벨을 만든다.
  final String? label;
  final ImportantDatePriority priority;
  final bool needsSourceEvidence;
}
