import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../l10n/generated/app_localizations.dart';

/// ONDAM 2.0 결과 화면의 "중요한 날짜" 섹션 — [AnalysisResultView] 전용
/// 하위 위젯으로 분리(단일 책임, flutter.md). [dates]가 null/empty면 아무것도
/// 그리지 않는다 — 빈 영역을 노출하지 않는다는 원칙(Phase 4 §2)을 호출부가
/// 신경 쓰지 않아도 되도록 이 위젯 스스로 지킨다. 날짜를 추측/생성하지
/// 않는다 — [dates]에 들어있는 값만 그대로 표시한다(Phase 4 §7).
class AnalysisImportantDatesSection extends StatelessWidget {
  const AnalysisImportantDatesSection({super.key, required this.dates});

  final List<ImportantDate>? dates;

  static const _priorityOrder = {
    ImportantDatePriority.high: 0,
    ImportantDatePriority.medium: 1,
    ImportantDatePriority.low: 2,
  };

  Map<ImportantDateKind, String> _kindLabels(AppLocalizations l10n) => {
    ImportantDateKind.paymentDue: l10n.dateKindPaymentDue,
    ImportantDateKind.visit: l10n.dateKindVisit,
    ImportantDateKind.applicationPeriod: l10n.dateKindApplicationPeriod,
    ImportantDateKind.expiration: l10n.dateKindExpiration,
    ImportantDateKind.reservation: l10n.dateKindReservation,
    ImportantDateKind.other: l10n.dateKindOther,
  };

  @override
  Widget build(BuildContext context) {
    final list = dates;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final kindLabels = _kindLabels(l10n);

    // 중요한 날짜가 먼저 보이도록 priority로 정렬 — 값을 새로 만들지 않고
    // 주어진 항목의 순서만 바꾼다.
    final sorted = [...list]
      ..sort((a, b) {
        final byPriority = _priorityOrder[a.priority]!.compareTo(
          _priorityOrder[b.priority]!,
        );
        if (byPriority != 0) return byPriority;
        return a.date.compareTo(b.date);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.importantDatesTitle),
        for (final date in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppInfoRow(
              label: date.label ?? kindLabels[date.kind]!,
              value: _formatDate(l10n, date.date),
            ),
          ),
      ],
    );
  }

  String _formatDate(AppLocalizations l10n, DateTime date) =>
      l10n.monthDayFormat(date.month, date.day);
}
