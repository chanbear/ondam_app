/// `demo_usage_stats` 행 하나 — QR 연결이 수락된 순간 자동 생성되는
/// 장식용 "몇 개월째 이용 중" 표시값이다. 실제 AI 분석 이력
/// (`analysis_results`)과는 무관하다 — UI는 이 값을 보여줄 때 항상 "데모"
/// 라벨을 함께 표시해 실제 안전 기록과 혼동되지 않게 해야 한다.
class DemoUsageStats {
  const DemoUsageStats({required this.since, required this.analysisCount});

  final DateTime since;
  final int analysisCount;
}
