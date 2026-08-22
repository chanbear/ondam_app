/// A single "해야 할 일" checklist entry derived from an analysis result
/// (예: "8월 25일까지 관리비 납부"). [completed]는 AI가 채우는 값이 아니라
/// 사용자가 직접 체크하는 상태이므로, 화면 표시 후 `copyWith`로 갱신한다 —
/// [AnalysisResult] 자체(서버가 만든 불변 분석 결과)와는 분리된 개념이다.
/// 현재는 세션 내에서만 토글되며(로컬 상태), 기기/세션을 넘어 영속화하려면
/// 별도 저장소나 DB 컬럼이 필요한지 이후 Phase에서 판단한다.
class ActionItem {
  const ActionItem({
    required this.id,
    required this.title,
    this.completed = false,
  });

  final String id;
  final String title;
  final bool completed;

  ActionItem copyWith({bool? completed}) {
    return ActionItem(
      id: id,
      title: title,
      completed: completed ?? this.completed,
    );
  }
}
