/// Shared shape for a single elder's schedule entry — owned by the
/// `schedule` feature in both apps (Senior: 기록 탭의 "일정" 섹션, Guardian:
/// 홈의 "다가오는 일정" 섹션. 같은 `schedules` 테이블을 서로 다른 뷰로 보여줄
/// 뿐, 별도 도메인으로 취급한다(feature-spec.md MODIFY-9— 확정).
///
/// 범용 일정(제목+날짜시간+완료여부) + 복약처럼 "매일 같은 시각 반복"하는
/// 단순 케이스만 지원한다 — RRULE 같은 복잡한 반복 규칙은 요구사항에 없다.
/// [isRecurring]이 true일 때만 [recurrenceHour]/[recurrenceMinute]가 채워져
/// 있고(매일 그 시각에 반복), 이 둘은 항상 [scheduledAt]의 시:분과 같은 값을
/// 갖는다 — 반복 여부와 무관하게 시각 입력은 한 번만 받는다(폼에서 별도로
/// 다시 묻지 않는다).
class Schedule {
  const Schedule({
    required this.id,
    required this.elderId,
    required this.title,
    required this.scheduledAt,
    required this.completed,
    required this.createdAt,
    this.isRecurring = false,
    this.recurrenceHour,
    this.recurrenceMinute,
  });

  final String id;
  final String elderId;
  final String title;
  final DateTime scheduledAt;
  final bool completed;
  final DateTime createdAt;
  final bool isRecurring;

  /// 0-23. [isRecurring]이 false면 항상 null.
  final int? recurrenceHour;

  /// 0-59. [isRecurring]이 false면 항상 null.
  final int? recurrenceMinute;
}
