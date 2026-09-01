import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../connection/presentation/providers/connected_elders_provider.dart';
import '../widgets/analysis_record_card.dart'
    show riskLabel, structuredFieldLabel, structuredFieldValue;

/// "받은 연락" 상세 — Guardian UI Application Round 1 §9~12의 승인된 공통
/// 구조를 따른다(prototype/guardian `renderAnalysisResult` 그대로): 위험도/
/// 중요도 → 날짜/기한 → AI 요약 → 해야 할 일 → 상세정보(기본 접힘, 신뢰도/
/// 원문/구조화 필드) → 확인 완료. Senior 앱의 "음성으로 질문하기"는 §9에
/// 따라 넣지 않는다.
///
/// "확인 완료"는 Guardian 쪽에 쓰기 위한 기존 backend 경로가 없어(§2 —
/// `confirmed_at`은 어르신 본인의 확인 시각이라 Guardian이 덮어쓸 대상이
/// 아니다, §11 "confirmed_at 관련 로직을 변경하지 않는다") 로컬 표시
/// 상태로만 둔다 — DB에 쓰지 않는다. 실제로 Guardian이 이 화면에서 무엇을
/// "확인"하는지(알림 읽음 처리와 별개인지)는 제품 결정이 필요해 이번
/// Round에서는 UI만 준비하고 기록으로 남긴다.
class AnalysisRecordDetailPage extends ConsumerStatefulWidget {
  const AnalysisRecordDetailPage({super.key, required this.result});

  final AnalysisResult result;

  @override
  ConsumerState<AnalysisRecordDetailPage> createState() =>
      _AnalysisRecordDetailPageState();
}

class _AnalysisRecordDetailPageState
    extends ConsumerState<AnalysisRecordDetailPage> {
  late List<ActionItem> _actionItems;
  late bool _confirmed;

  static const _datePriorityOrder = {
    ImportantDatePriority.high: 0,
    ImportantDatePriority.medium: 1,
    ImportantDatePriority.low: 2,
  };

  @override
  void initState() {
    super.initState();
    _actionItems = List.of(widget.result.actionItems ?? const []);
    // 기록에서 다시 연 결과라면 confirmedAt이 이미 채워져 있을 수 있다 —
    // 그 경우 로컬 state를 다시 false로 시작하지 않는다.
    _confirmed = widget.result.confirmedAt != null;
  }

  void _onActionItemChanged(ActionItem changed) {
    final index = _actionItems.indexWhere((item) => item.id == changed.id);
    if (index == -1) return;
    setState(() => _actionItems[index] = changed);
  }

  String? _elderName(String elderId) {
    for (final elder in ref.read(connectedEldersProvider)) {
      if (elder.id == elderId) return elder.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = widget.result;
    final risk = result.riskLevel;
    final elderName = _elderName(result.elderId);
    final dates = [...result.importantDates ?? const <ImportantDate>[]]
      ..sort((a, b) {
        final byPriority = _datePriorityOrder[a.priority]!.compareTo(
          _datePriorityOrder[b.priority]!,
        );
        if (byPriority != 0) return byPriority;
        return a.date.compareTo(b.date);
      });

    return AppScaffold(
      title: result.type == AnalysisType.document
          ? l10n.documentDetailTitle
          : l10n.messageDetailTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 위험도/중요도 — risk가 없는 기존 데이터는 배지 없이 넘어간다.
          if (risk != null) ...[
            AppRiskBadge(level: risk, label: riskLabel(l10n, risk)),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            [_formatDate(result.createdAt), ?elderName].join(' · '),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. 날짜/기한 — 없으면 영역 자체를 숨긴다.
          if (dates.isNotEmpty) ...[
            for (final date in dates) ...[
              AnalysisDateCard(date: date),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],

          // 3. AI 요약
          AnalysisSummary(summary: result.summary),
          const SizedBox(height: AppSpacing.xl),

          // 4. 해야 할 일 — 없으면 영역 자체를 숨긴다.
          if (_actionItems.isNotEmpty) ...[
            AnalysisActionList(
              items: _actionItems,
              onChanged: _onActionItemChanged,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // 5. 상세정보 — 기본 접힘.
          _DetailsSection(result: result, l10n: l10n),
          const SizedBox(height: AppSpacing.xl),

          // 6. 확인 완료
          _ConfirmSection(
            confirmed: _confirmed,
            l10n: l10n,
            onConfirm: () => setState(() => _confirmed = true),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${_pad(date.month)}.${_pad(date.day)}';

  String _pad(int value) => value.toString().padLeft(2, '0');
}

/// "상세정보 보기" — 기본 접힘, 신뢰도(%)/구조화 필드/원문을 담는다
/// (prototype `<details>` 그대로). Native `ExpansionTile`을 쓴다 — Design
/// System에 collapsible 컴포넌트가 없다고 새로 만들지 않는다(Senior
/// `AnalysisResultView`의 `_DetailsSection`과 동일한 결정).
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.result, required this.l10n});

  final AnalysisResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final structuredFields = result.structuredFields;
    final sourceExcerpt = result.sourceExcerpt;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            l10n.detailsToggleTitle,
            style: AppTextStyles.titleMedium,
          ),
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
                AppInfoRow(
                  label: structuredFieldLabel(l10n, entry.key),
                  value: structuredFieldValue(l10n, entry.key, entry.value),
                ),
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

/// "확인 완료" — 로컬 표시 상태만 바꾼다(클래스 문서 참고, 서버에 쓰지
/// 않는다).
class _ConfirmSection extends StatelessWidget {
  const _ConfirmSection({
    required this.confirmed,
    required this.l10n,
    required this.onConfirm,
  });

  final bool confirmed;
  final AppLocalizations l10n;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    if (confirmed) {
      return Semantics(
        liveRegion: true,
        label: l10n.confirmedBannerLabel,
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.confirmedBannerLabel,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.success),
            ),
          ],
        ),
      );
    }
    return AnalysisConfirmButton(
      label: l10n.confirmButtonLabel,
      onConfirm: onConfirm,
    );
  }
}
