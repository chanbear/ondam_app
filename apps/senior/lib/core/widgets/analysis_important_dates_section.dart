import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

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

  static const _kindLabels = {
    ImportantDateKind.paymentDue: '납부 기한',
    ImportantDateKind.visit: '방문 날짜',
    ImportantDateKind.applicationPeriod: '신청 기간',
    ImportantDateKind.expiration: '만료일',
    ImportantDateKind.reservation: '예약 날짜',
    ImportantDateKind.other: '기타 중요한 날짜',
  };

  @override
  Widget build(BuildContext context) {
    final list = dates;
    if (list == null || list.isEmpty) return const SizedBox.shrink();

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
        const AppSectionHeader(title: '중요한 날짜'),
        for (final date in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppInfoRow(
              label: date.label ?? _kindLabels[date.kind]!,
              value: _formatDate(date.date),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.month}월 ${date.day}일';
}
