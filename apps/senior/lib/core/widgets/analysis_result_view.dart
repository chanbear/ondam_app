import 'package:flutter/material.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../l10n/generated/app_localizations.dart';
import 'analysis_action_checklist.dart';

/// Renders a completed [AnalysisResult] — ONDAM 2.0 결과 화면. Shared by
/// `document_scan`과 `message_check`: 두 feature가 동일한 [AnalysisResult]
/// shape를 만들고, 이 위젯 하나로 그린다(architecture.md "두 개 이상의
/// feature가 실제로 공유하는 위젯만 core/widgets에 둔다"). `core/widgets`는
/// feature를 모르는 계층이라 음성 비서 화면 이동/확인 완료 저장은 직접
/// 하지 않고 [onAskByVoice]/[onConfirm] 콜백으로 호출부(각 feature의 결과
/// 페이지)에 위임한다.
///
/// 정보 순서(Phase 44, PHASE 40 프로토타입 `renderAnalysisResult` 그대로) —
/// 위험도 → 날짜/기한 → AI 요약 → 해야 할 일 → 상세정보(기본 접힘) →
/// 음성 질문 → 확인 완료. actionItems/importantDates/clarifyingQuestions는
/// 아직 어떤 백엔드도 채우지 않아 null일 수 있으므로 비어있으면 해당 섹션
/// 자체를 숨긴다(빈 영역 노출 금지).
class AnalysisResultView extends StatefulWidget {
  const AnalysisResultView({
    super.key,
    required this.result,
    required this.onAskByVoice,
    this.onConfirm,
    this.easyMode = false,
  });

  final AnalysisResult result;

  /// 음성 비서 화면으로 이동하는 동작 — 실제 네비게이션은 호출부(feature
  /// layer)가 결정한다. 이 위젯은 언제 호출할지만 안다.
  final VoidCallback onAskByVoice;

  /// "확인 완료"를 실제로 서버에 저장한다(ONDAM 2.0 요구사항 20/29). null이면
  /// (콜백 미제공) 로컬 상태만 바뀌고 저장하지 않는다 — 저장이 필요 없는
  /// 미리보기 등 하위 호환 경로.
  final Future<Result<void>> Function()? onConfirm;

  /// 쉬운 모드 여부 — "확인 완료"/음성 비서 버튼의 터치 영역을 키운다.
  final bool easyMode;

  @override
  State<AnalysisResultView> createState() => _AnalysisResultViewState();
}

class _AnalysisResultViewState extends State<AnalysisResultView> {
  // 체크리스트 완료 상태는 이 화면 안에서만 의미 있는 로컬 UI 상태다 —
  // [AnalysisResult]는 서버가 만든 불변 값이므로 여기서 바꾸지 않는다.
  late List<ActionItem> _actionItems;
  late bool _confirmed;
  bool _confirming = false;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _actionItems = List.of(widget.result.actionItems ?? const []);
    // 기록에서 다시 연 결과라면 confirmedAt이 이미 채워져 있을 수 있다 —
    // 그 경우 로컬 state를 다시 false로 시작하지 않는다(ONDAM 2.0
    // 요구사항 20/29: 다시 열어도 확인 완료 상태 유지).
    _confirmed = widget.result.confirmedAt != null;
  }

  void _toggleActionItem(int index) {
    setState(() {
      _actionItems[index] = _actionItems[index].copyWith(
        completed: !_actionItems[index].completed,
      );
    });
  }

  Future<void> _confirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      setState(() => _confirmed = true);
      return;
    }
    setState(() {
      _confirming = true;
      _confirmError = null;
    });
    final result = await onConfirm();
    if (!mounted) return;
    setState(() {
      _confirming = false;
      switch (result) {
        case Ok():
          _confirmed = true;
        case Err(:final failure):
          _confirmError = failure.message;
      }
    });
  }

  static const _datePriorityOrder = {
    ImportantDatePriority.high: 0,
    ImportantDatePriority.medium: 1,
    ImportantDatePriority.low: 2,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = widget.result;
    final risk = result.riskLevel;
    // 중요한 날짜가 먼저 보이도록 priority로 정렬 — 값을 새로 만들지 않고
    // 주어진 항목의 순서만 바꾼다(기존 AnalysisImportantDatesSection과
    // 동일한 정렬 규칙).
    final dates = [...result.importantDates ?? const <ImportantDate>[]]
      ..sort((a, b) {
        final byPriority = _datePriorityOrder[a.priority]!.compareTo(
          _datePriorityOrder[b.priority]!,
        );
        if (byPriority != 0) return byPriority;
        return a.date.compareTo(b.date);
      });
    final buttonSize = widget.easyMode
        ? AppButtonSize.large
        : AppButtonSize.standard;

    return ListView(
      children: [
        // 위험도 + 신뢰도 — ui-prototype `analysisResultBody()`의
        // `rsl-risk-row` 카드(두 값을 divider로 나눈 한 카드)를 따라 함께
        // 묶는다. risk가 null인 기존 데이터는 배지 없이 신뢰도만 보여준다
        // (색만으로 전달하지 않는다는 원칙은 지키되, 없는 값을 지어내지
        // 않는다).
        AppCard(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (risk != null) ...[
                  Expanded(
                    child: AppRiskBadge(
                      level: risk,
                      label: _riskBadgeLabel(l10n, risk),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const VerticalDivider(color: AppColors.divider, width: 1),
                  const SizedBox(width: AppSpacing.md),
                ],
                // 신뢰도는 percentage가 아니라 문장 하나만
                // (AppConfidenceIndicator 자체 문서 참고 — 요약을 읽기 전에
                // 얼마나 믿을지 먼저 알려주는 신뢰 보정 용도). 정확한 퍼센트
                // 수치는 "상세정보"에서 확인한다.
                Expanded(
                  child: AppConfidenceIndicator(
                    level: result.reliability,
                    showPercentage: true,
                    showStars: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: AppInfoRow(
            label: _typeLabel(l10n, result.type),
            value: _formatDate(result.createdAt),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 날짜/기한 — 없으면 영역 자체를 숨긴다.
        if (dates.isNotEmpty) ...[
          AppSectionHeader(title: l10n.importantDatesTitle),
          for (final date in dates) ...[
            AnalysisDateCard(date: date),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],

        // AI 요약 — 최대 4줄. 날짜 카드와 같은 날짜를 표시 단계에서만 걷어낸다
        // (AI 원본 summary 자체는 바꾸지 않는다, Phase 44 §7).
        AnalysisSummary(
          summary: _summaryWithoutDuplicateDates(result.summary, dates),
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.xl),

        // 해야 할 일 — 기존 AnalysisActionChecklist를 그대로 쓴다: 새
        // design_system AnalysisActionList는 체크박스만 탭 영역인 반면,
        // 이 위젯은 행 전체를 탭 영역으로 넓힌 접근성 결정(각주 참고)이 있어
        // Phase 44에서 교체하지 않는다.
        AnalysisActionChecklist(
          items: _actionItems,
          onToggle: _toggleActionItem,
        ),
        if (_actionItems.isNotEmpty) const SizedBox(height: AppSpacing.xl),

        // 상세정보 — 기본 접힘(신뢰도는 항상, 원문/구조화 필드는 있을 때만).
        _DetailsSection(result: result),
        const SizedBox(height: AppSpacing.xl),

        // 음성 질문 — Senior 전용, 항상 진입 가능(AI가 준 질문이 없는 것과
        // "더 물어볼 방법이 없는 것"은 다르다).
        _VoiceQuestionSection(
          questions: result.clarifyingQuestions,
          onAskByVoice: widget.onAskByVoice,
        ),
        const SizedBox(height: AppSpacing.xl),

        // 확인 완료
        _ConfirmDoneSection(
          confirmed: _confirmed,
          confirming: _confirming,
          error: _confirmError,
          buttonSize: buttonSize,
          onConfirm: _confirm,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${_pad(date.month)}.${_pad(date.day)}';

  String _pad(int value) => value.toString().padLeft(2, '0');

  String _typeLabel(AppLocalizations l10n, AnalysisType type) =>
      type == AnalysisType.document
      ? l10n.analysisTypeDocumentLabel
      : l10n.analysisTypeMessageLabel;

  String _riskBadgeLabel(AppLocalizations l10n, RiskLevel level) =>
      switch (level) {
        RiskLevel.safe => l10n.riskSafeLabel,
        RiskLevel.caution => l10n.riskCautionLabel,
        RiskLevel.dangerous => l10n.riskDangerousLabel,
      };
}

/// 요약 텍스트에서 이미 날짜 카드로 보여준 날짜와 같은 표현을 걷어낸다 —
/// AI 원본 [AnalysisResult.summary]는 바꾸지 않고 화면에 그릴 때만
/// 적용한다(Phase 42 "날짜 카드와 AI 요약 날짜 중복" 문제, Phase 44 §7).
/// [ImportantDate]와 정확히 같은 "N월 N일" 표현만 지운다 — 느슨한 정규식으로
/// 무관한 숫자까지 지우지 않는다.
/// ponytail: 지운 자리에 남는 조사/구두점까지 다듬는 자연어 처리는 이
/// 용도(가벼운 중복 제거)에는 과함 — extractKeyPoint와 같은 판단.
String _summaryWithoutDuplicateDates(
  String summary,
  List<ImportantDate> dates,
) {
  if (dates.isEmpty) return summary;
  var result = summary;
  for (final date in dates) {
    final mention = '${date.date.month}월 ${date.date.day}일';
    result = result.replaceAll(mention, '');
  }
  result = result.replaceAll(RegExp(r' {2,}'), ' ').trim();
  return result.isEmpty ? summary : result;
}

/// "상세정보 보기" — 기본 접힘, 신뢰도(%)/구조화 필드/원문을 담는다
/// (prototype `<details>` 그대로). Native `ExpansionTile`을 쓴다 —
/// Design System에 collapsible 컴포넌트가 없다고 새로 만들지 않는다.
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final structuredFields = result.structuredFields;
    final sourceExcerpt = result.sourceExcerpt;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(l10n.detailsViewTitle, style: AppTextStyles.titleMedium),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            AppInfoRow(
              label: l10n.reliabilityLabel,
              value: '${result.reliability.displayPercent}%',
            ),
            if (structuredFields != null && structuredFields.isNotEmpty)
              for (final entry in structuredFields.entries)
                AppInfoRow(label: entry.key, value: '${entry.value}'),
            if (sourceExcerpt != null && sourceExcerpt.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.sourceTextLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(sourceExcerpt, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// "이 내용 물어보기" — prototype 버튼 문구 그대로. AI가 준 후속 질문
/// ([questions])이 있으면 짧게 나열한 뒤 같은 진입점을 보여준다.
class _VoiceQuestionSection extends StatelessWidget {
  const _VoiceQuestionSection({
    required this.questions,
    required this.onAskByVoice,
  });

  final List<String>? questions;
  final VoidCallback onAskByVoice;

  @override
  Widget build(BuildContext context) {
    final list = questions;
    final hasQuestions = list != null && list.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasQuestions) ...[
          for (final question in list)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('· $question', style: AppTextStyles.bodyMedium),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnalysisVoiceQuestion(
          question: AppLocalizations.of(context)!.askAboutThisButton,
          onAnswer: onAskByVoice,
        ),
      ],
    );
  }
}

/// "확인 완료" — [AnalysisResultView.onConfirm]이 있으면 실제 서버 저장을
/// 기다렸다가 성공한 뒤에만 완료로 표시한다(ONDAM 2.0 요구사항 20/29: 저장
/// 성공 전에 영구 저장된 것처럼 보이면 안 된다). 실패하면 오류를 보여주고
/// 다시 시도할 수 있게 버튼을 그대로 둔다. [Semantics]로 눌렀을 때 상태가
/// 바뀌었음을 스크린리더가 읽을 수 있게 한다.
///
/// 문구("확인 완료"/"확인 완료했어요")는 Phase 44 §7에서 재검토했다 —
/// prototype(`renderAnalysisResult`)의 실제 버튼/배너 문구와 이미 일치하고,
/// Phase 42가 지적한 "확인이 필요해요"(주의 등급 위험 배지 라벨, 별개
/// Design System 컴포넌트)와의 혼동은 배지 쪽 문구 조정이 필요한 사안이라
/// 이번 화면 단위 작업 범위 밖으로 남겨둔다(변경하지 않음).
class _ConfirmDoneSection extends StatelessWidget {
  const _ConfirmDoneSection({
    required this.confirmed,
    required this.confirming,
    required this.error,
    required this.buttonSize,
    required this.onConfirm,
  });

  final bool confirmed;
  final bool confirming;
  final String? error;
  final AppButtonSize buttonSize;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (confirmed) {
      return Semantics(
        liveRegion: true,
        label: l10n.confirmedDoneSemanticLabel,
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.confirmedDoneMessage,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.success),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null) ...[
          Text(
            error!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnalysisConfirmButton(
          label: l10n.confirmDoneButton,
          onConfirm: confirming ? null : onConfirm,
          isLoading: confirming,
          large: buttonSize == AppButtonSize.large,
        ),
      ],
    );
  }
}
