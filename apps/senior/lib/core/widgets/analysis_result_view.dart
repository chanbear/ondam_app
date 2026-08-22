import 'package:flutter/material.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import 'analysis_action_checklist.dart';
import 'analysis_clarifying_questions_section.dart';
import 'analysis_important_dates_section.dart';
import 'analysis_key_point_section.dart';

/// Renders a completed [AnalysisResult] — ONDAM 2.0 결과 화면. Shared by
/// `document_scan`과 `message_check`: 두 feature가 동일한 [AnalysisResult]
/// shape를 만들고, 이 위젯 하나로 그린다(architecture.md "두 개 이상의
/// feature가 실제로 공유하는 위젯만 core/widgets에 둔다"). `core/widgets`는
/// feature를 모르는 계층이라 음성 비서 화면 이동/확인 완료 저장은 직접
/// 하지 않고 [onAskByVoice]/[onConfirm] 콜백으로 호출부(각 feature의 결과
/// 페이지)에 위임한다.
///
/// 정보 우선순위(ONDAM 2.0 요구사항 14/15/23/24) — 신뢰도 → 위험도 →
/// 중요한 날짜 → 주요 내용(아주 짧게) → AI 요약(최대 4줄) → 문서 정보 →
/// 해야 할 일 → 궁금한 점 → 확인 완료. actionItems/importantDates/
/// clarifyingQuestions는 아직 어떤 백엔드도 채우지 않아 null일 수 있으므로
/// 비어있으면 해당 섹션 자체를 숨긴다(빈 영역 노출 금지).
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

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final risk = result.riskLevel;
    final structuredFields = result.structuredFields;
    final buttonSize = widget.easyMode
        ? AppButtonSize.large
        : AppButtonSize.standard;

    return ListView(
      children: [
        AppConfidenceIndicator(level: result.reliability, showPercentage: true),
        const SizedBox(height: AppSpacing.lg),
        // riskLevel과 reliability는 서로 다른 축이다 — 하나로 다른 하나를
        // 계산하거나 보정하지 않는다. risk가 null인 기존 데이터는 그냥
        // 배지/카드 없이 넘어간다.
        if (risk != null) ...[
          AppRiskBadge(level: risk),
          const SizedBox(height: AppSpacing.md),
        ],
        // 정해진 기한/날짜를 주요 내용/요약보다 먼저 보여준다(요구사항
        // 15/24 "우선적으로 표시").
        AnalysisImportantDatesSection(dates: result.importantDates),
        if (result.importantDates?.isNotEmpty ?? false)
          const SizedBox(height: AppSpacing.xl),
        // "주요 내용"(아주 짧게)과 "AI 요약"(최대 4줄)을 분리한다(요구사항
        // 14/23) — 긴 요약문을 먼저 보여주지 않는다.
        AnalysisKeyPointSection(summary: result.summary),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'AI 요약'),
        const SizedBox(height: AppSpacing.sm),
        if (risk != null)
          AppAlertCard(level: risk, title: result.summary, titleMaxLines: 4)
        else
          AppStatusCard(
            message: result.summary,
            icon: Icons.description_outlined,
            messageMaxLines: 4,
          ),
        const SizedBox(height: AppSpacing.xl),
        if (structuredFields != null && structuredFields.isNotEmpty) ...[
          const AppSectionHeader(title: '문서 정보'),
          for (final entry in structuredFields.entries)
            AppInfoRow(label: entry.key, value: '${entry.value}'),
          const SizedBox(height: AppSpacing.xl),
        ],
        AnalysisActionChecklist(
          items: _actionItems,
          onToggle: _toggleActionItem,
        ),
        if (_actionItems.isNotEmpty) const SizedBox(height: AppSpacing.xl),
        AnalysisClarifyingQuestionsSection(
          questions: result.clarifyingQuestions,
          onAskByVoice: widget.onAskByVoice,
          buttonSize: buttonSize,
        ),
        const SizedBox(height: AppSpacing.xl),
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
}

/// "확인 완료" — [AnalysisResultView.onConfirm]이 있으면 실제 서버 저장을
/// 기다렸다가 성공한 뒤에만 완료로 표시한다(ONDAM 2.0 요구사항 20/29:
/// 저장 성공 전에 영구 저장된 것처럼 보이면 안 된다). 실패하면 오류를
/// 보여주고 다시 시도할 수 있게 버튼을 그대로 둔다. [Semantics]로 눌렀을
/// 때 상태가 바뀌었음을 스크린리더가 읽을 수 있게 한다.
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
    if (confirmed) {
      return Semantics(
        liveRegion: true,
        label: '확인 완료로 표시했어요',
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '확인했어요',
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
        AppButton(
          label: '확인 완료',
          isLoading: confirming,
          onPressed: confirming ? null : onConfirm,
          size: buttonSize,
        ),
      ],
    );
  }
}
