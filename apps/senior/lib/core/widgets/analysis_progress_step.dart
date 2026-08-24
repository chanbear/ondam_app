import '../../l10n/generated/app_localizations.dart';

/// 문서/문자 분석 진행 단계 — ONDAM 2.0 요구사항 12/21. 실제 AI 서버가
/// 정밀한 진행률(예: 37%, 62%)을 보내주지 않으므로, 클라이언트가 아는
/// 사실만으로 안전하게 표현 가능한 "단계"만 사용한다. 마지막 단계
/// ([finishing])를 넘어서는 값(100%)은 절대 표시하지 않는다 — 실제 분석이
/// 끝나면 이 진행 화면 자체가 결과 화면으로 바뀌어 사라진다.
enum AnalysisProgressStep {
  preparing(10),
  sending(35),
  analyzing(70),
  finishing(90);

  const AnalysisProgressStep(this.percent);

  /// 0~100 표시용 값 — 실제 AI 진행률이 아니라 "지금 어느 단계인지"를
  /// 나타내는 대표값이다.
  final int percent;

  /// 화면에 보여줄 문구 — enum은 BuildContext를 가질 수 없으므로(순수
  /// Dart 값), 호출부(위젯의 build())가 [AppLocalizations]를 전달한다.
  String label(AppLocalizations l10n) => switch (this) {
    AnalysisProgressStep.preparing => l10n.progressPreparing,
    AnalysisProgressStep.sending => l10n.progressSending,
    AnalysisProgressStep.analyzing => l10n.progressAnalyzing,
    AnalysisProgressStep.finishing => l10n.progressFinishing,
  };

  /// 다음 단계, 마지막 단계([finishing])면 null(더 진행하지 않음).
  AnalysisProgressStep? get next => switch (this) {
    AnalysisProgressStep.preparing => AnalysisProgressStep.sending,
    AnalysisProgressStep.sending => AnalysisProgressStep.analyzing,
    AnalysisProgressStep.analyzing => AnalysisProgressStep.finishing,
    AnalysisProgressStep.finishing => null,
  };
}
