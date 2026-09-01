import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../l10n/generated/app_localizations.dart';
import '../voice_guide/voice_guide_provider.dart';
import '../voice_guide/voice_guide_service.dart';
import 'structured_field_labels.dart';

/// Easy Mode 전용 분석 결과 화면 — `AnalysisResultView`(Normal Mode, 정보
/// 밀도 높은 기존 화면)는 절대 수정하지 않고, 완전히 별도 위젯으로 둔다.
/// document_scan/message_check 두 feature가 공유하므로 core/widgets에 둔다.
///
/// 2026-08-28(8차) — 사용자가 만든 HTML 목업(건강검진 안내 참고 디자인을
/// ONDAM 토큰으로 재구성한 것)을 "완전히 똑같이" 이 위젯에 옮긴다: 연한
/// 파란 배너 카드(배지+헤드라인) → 그라디언트 일러스트 패널 → 기한 하이라이트
/// 카드(얇은 테두리) → 문서/문자 종류 태그 + 상세정보 펼침 카드 → AI 요약
/// 카드 → 체크리스트(번호 배지 + "다시 듣기" 재생 버튼) → 물어보기 → 확인
/// 완료. 굵은 먹색 테두리 대신 `AppCard`(얇은 1px `AppColors.border`)를
/// 그대로 재사용한다 — 새 카드 스타일을 만들지 않는다.
///
/// 실제 [AnalysisResult]에는 목업의 "국민건강보험공단" 같은 구체적 고정
/// 문구가 없다 — 지어내지 않고, 있는 필드([structuredFields]/
/// [sourceExcerpt]/[summary]/[actionItems])만 쓴다.
class EasyAnalysisResultView extends ConsumerStatefulWidget {
  const EasyAnalysisResultView({
    super.key,
    required this.result,
    required this.onAskByVoice,
    this.onConfirm,
  });

  final AnalysisResult result;
  final VoidCallback onAskByVoice;

  /// null이면 로컬 상태만 "확인 완료"로 바꾼다(서버 저장 없음) —
  /// `AnalysisResultView.onConfirm`과 동일한 규약.
  final Future<Result<void>> Function()? onConfirm;

  @override
  ConsumerState<EasyAnalysisResultView> createState() =>
      _EasyAnalysisResultViewState();
}

class _EasyAnalysisResultViewState
    extends ConsumerState<EasyAnalysisResultView> {
  late bool _confirmed = widget.result.confirmedAt != null;
  bool _confirming = false;
  String? _confirmError;
  bool _voiceGuideSpoken = false;
  // dispose()에서는 ref.read()가 안전하지 않다(ConsumerState가 이미
  // unmount 중일 수 있음) — initState에서 미리 읽어 필드에 저장해둔다.
  late final VoiceGuideService _voiceGuideService;

  @override
  void initState() {
    super.initState();
    _voiceGuideService = ref.read(voiceGuideServiceProvider);
  }

  @override
  void dispose() {
    _voiceGuideService.stop();
    super.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    final result = widget.result;
    final isDoc = result.type == AnalysisType.document;
    final visual = _riskVisual(result.riskLevel);

    if (!_voiceGuideSpoken) {
      _voiceGuideSpoken = true;
      final guideText = '${l10n.easyResultVoiceGuidePrefix} ${result.summary}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        speakScreenGuide(ref, guideText);
      });
    }

    final dates = [...?result.importantDates]
      ..sort((a, b) => a.date.compareTo(b.date));
    final highlightDate = dates.isEmpty ? null : dates.first;
    final actionItems = result.actionItems ?? const <ActionItem>[];
    final structuredFields = result.structuredFields;
    final typeTag = (structuredFields == null || structuredFields.isEmpty)
        ? null
        : structuredFieldValue(
            l10n,
            structuredFields.entries.first.key,
            structuredFields.entries.first.value,
          );
    final structuredFieldRows = [
      for (final entry
          in structuredFields?.entries ?? const <MapEntry<String, Object?>>[])
        MapEntry(
          structuredFieldLabel(l10n, entry.key),
          structuredFieldValue(l10n, entry.key, entry.value),
        ),
    ];
    final sourceExcerpt = result.sourceExcerpt;
    final hasDetails =
        (structuredFields != null && structuredFields.isNotEmpty) ||
        (sourceExcerpt != null && sourceExcerpt.isNotEmpty);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _ResultBanner(l10n: l10n, visual: visual, riskLevel: result.riskLevel),
        const SizedBox(height: AppSpacing.md),
        _EasyResultIllustration(isDoc: isDoc, visual: visual),
        if (highlightDate != null) ...[
          const SizedBox(height: AppSpacing.md),
          _HighlightCard(date: highlightDate, visual: visual),
        ],
        if (typeTag != null || hasDetails) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailsCard(
            typeTag: typeTag,
            typeLabel: l10n.easyResultTypeLabel,
            detailsTitle: l10n.detailsViewTitle,
            reliabilityLabel: l10n.reliabilityLabel,
            reliability: result.reliability,
            structuredFieldRows: structuredFieldRows,
            sourceTextLabel: l10n.sourceTextLabel,
            sourceExcerpt: sourceExcerpt,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.smart_toy,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.easyResultAiSummaryLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(result.summary, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
        if (actionItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                for (var i = 0; i < actionItems.length; i++)
                  _ChecklistRow(
                    index: i + 1,
                    item: actionItems[i],
                    replayLabel: l10n.easyResultReplayLabel,
                    isLast: i == actionItems.length - 1,
                    onReplay: () =>
                        _voiceGuideService.speak(actionItems[i].title),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AnalysisVoiceQuestion(
          question: l10n.askAboutThisButton,
          onAnswer: widget.onAskByVoice,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_confirmed)
          Semantics(
            liveRegion: true,
            label: l10n.confirmedDoneSemanticLabel,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.confirmedDoneMessage,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (_confirmError != null) ...[
            Text(
              _confirmError!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AnalysisConfirmButton(
            label: l10n.confirmDoneButton,
            onConfirm: _confirming ? null : _confirm,
            isLoading: _confirming,
            large: true,
          ),
        ],
      ],
    );
  }
}

class _RiskVisual {
  const _RiskVisual(this.color, this.softColor, this.icon);
  final Color color;
  final Color softColor;
  final IconData icon;
}

_RiskVisual _riskVisual(RiskLevel? level) => switch (level) {
  RiskLevel.safe || null => const _RiskVisual(
    AppEasyMode.success,
    AppColors.successSoft,
    Icons.verified,
  ),
  RiskLevel.caution => const _RiskVisual(
    AppEasyMode.warning,
    AppColors.warningSoft,
    Icons.error,
  ),
  RiskLevel.dangerous => const _RiskVisual(
    AppEasyMode.danger,
    AppColors.errorSoft,
    Icons.warning,
  ),
};

String _riskLabel(AppLocalizations l10n, RiskLevel? level) => switch (level) {
  RiskLevel.safe || null => l10n.riskSafeLabel,
  RiskLevel.caution => l10n.riskCautionLabel,
  RiskLevel.dangerous => l10n.riskDangerousLabel,
};

/// 상단 배너 — 목업의 연한 파란 배경 카드(`AppColors.primarySoft`, 항상
/// 파란 배경 고정, 위험도와 무관) 안에 위험도색 원형 배지 + 굵은 헤드라인.
/// 배지 색만으로 위험도를 전달하지 않도록 헤드라인 텍스트도 위험도색을
/// 유지한다(ui-principles.md "색상만으로 전달 금지").
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.l10n,
    required this.visual,
    required this.riskLevel,
  });

  final AppLocalizations l10n;
  final _RiskVisual visual;
  final RiskLevel? riskLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: visual.color,
              shape: BoxShape.circle,
            ),
            child: Icon(visual.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _riskLabel(l10n, riskLevel),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(color: visual.color),
          ),
        ],
      ),
    );
  }
}

/// 기한/보낸사람 하이라이트 카드 — 라벨 → 큰 값 → 위험도 색 보조문구.
/// 보조문구는 실제 [date]로부터 계산한 남은 기간이다(지어낸 문구 없음).
class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.date, required this.visual});

  final ImportantDate date;
  final _RiskVisual visual;

  static String _kindLabel(ImportantDateKind kind) => switch (kind) {
    ImportantDateKind.paymentDue => '납부 기한',
    ImportantDateKind.visit => '방문 날짜',
    ImportantDateKind.applicationPeriod => '신청 기간',
    ImportantDateKind.expiration => '만료일',
    ImportantDateKind.reservation => '예약 날짜',
    ImportantDateKind.other => '기타 일정',
  };

  static String _formatDate(DateTime date) => '${date.month}월 ${date.day}일';

  String _remainingNote(DateTime date) {
    final today = DateTime.now();
    final dueDay = DateTime(date.year, date.month, date.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final daysLeft = dueDay.difference(todayDay).inDays;
    if (daysLeft < 0) return '기한이 지났어요';
    if (daysLeft == 0) return '오늘까지예요';
    if (daysLeft <= 3) return '$daysLeft일 남았어요';
    return '여유 있게 남았어요';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            date.label ?? _kindLabel(date.kind),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(_formatDate(date.date), style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _remainingNote(date.date),
            style: AppTextStyles.bodyMedium.copyWith(
              color: visual.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 종류 태그 + "상세정보 보기"(원문 보기) 펼침 — 목업의 "문서 종류" 카드를
/// 그대로 옮긴다. `ExpansionTile`은 Normal Mode `_DetailsSection`과 같은
/// 패턴(Design System에 collapsible 컴포넌트가 없다고 새로 만들지 않는다).
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.typeTag,
    required this.typeLabel,
    required this.detailsTitle,
    required this.reliabilityLabel,
    required this.reliability,
    required this.structuredFieldRows,
    required this.sourceTextLabel,
    required this.sourceExcerpt,
  });

  final String? typeTag;
  final String typeLabel;
  final String detailsTitle;
  final String reliabilityLabel;
  final ReliabilityLevel reliability;
  final List<MapEntry<String, String>> structuredFieldRows;
  final String sourceTextLabel;
  final String? sourceExcerpt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (typeTag != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    typeTag!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(detailsTitle, style: AppTextStyles.titleMedium),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            AppInfoRow(
              label: reliabilityLabel,
              value: '${reliability.displayPercent}%',
            ),
            for (final row in structuredFieldRows)
              AppInfoRow(label: row.key, value: row.value),
            if (sourceExcerpt != null && sourceExcerpt!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                sourceTextLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(sourceExcerpt!, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// 체크리스트 한 줄 — 번호 배지 + 빈 체크박스 + 문구 + "다시 듣기" 재생
/// 버튼(눌렀을 때 [onReplay]로 이 항목만 다시 읽어준다). 설정의 음성 안내
/// on/off와 무관하게 항상 동작한다 — 사용자가 명시적으로 요청한 재생이다.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.index,
    required this.item,
    required this.replayLabel,
    required this.isLast,
    required this.onReplay,
  });

  final int index;
  final ActionItem item;
  final String replayLabel;
  final bool isLast;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderStrong, width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(item.title, style: AppTextStyles.bodyMedium)),
          const SizedBox(width: AppSpacing.sm),
          _ReplayChip(label: replayLabel, onTap: onReplay),
        ],
      ),
    );
  }
}

class _ReplayChip extends StatelessWidget {
  const _ReplayChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primarySoft, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay, size: 13, color: AppColors.primary),
              const SizedBox(width: 3),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 문서/문자를 나타내는 일러스트 — 2026-08-31 사용자 요청으로 손그림
/// Container/Icon 조합 대신 GPT(gpt-image-1)로 한 번 생성해 둔 정적
/// 이미지(`assets/images/easy_result_illustration_{doc,msg}.png`, ui-prototype
/// `assets/illustrations/`와 동일 원본)를 쓴다. 위험도별로 다시 생성하면
/// 호출 비용이 계속 들어서, 시나리오당(문서/문자) 한 장만 두고 위험도
/// 구분은 기존처럼 우측 하단 배지 색으로만 전달한다.
class _EasyResultIllustration extends StatelessWidget {
  const _EasyResultIllustration({required this.isDoc, required this.visual});

  final bool isDoc;
  final _RiskVisual visual;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 이미지 자체에 둥근 카드 프레임이 이미 포함돼 있어(생성 프롬프트)
          // BoxFit.cover로 자르지 않고 contain으로 전체를 보여준다.
          Center(
            child: Image.asset(
              isDoc
                  ? 'assets/images/easy_result_illustration_doc.png'
                  : 'assets/images/easy_result_illustration_msg.png',
              height: 170,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: visual.color,
                shape: BoxShape.circle,
              ),
              child: Icon(visual.icon, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
