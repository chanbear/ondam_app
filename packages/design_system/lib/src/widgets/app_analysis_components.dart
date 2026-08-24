import 'package:flutter/material.dart';
import 'package:ondam_models/ondam_models.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import 'app_alert_card.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_confidence_indicator.dart';
import 'app_info_row.dart';
import 'app_section_header.dart';

/// 향후 문서/문자 분석 결과 화면(`analysis` feature)이 공유할 컴포넌트
/// 골격 — Phase 43은 화면을 완성하지 않고 구조만 준비한다. 전부 기존
/// AppAlertCard/AppCard/AppInfoRow/AppConfidenceIndicator/AppButton을
/// 조립한 것일 뿐, 새 스타일 규칙을 만들지 않는다.

/// 위험도 + 요약 + (있으면) AI 신뢰도를 한 번에 보여주는 결과 화면 헤더.
class AnalysisRiskHeader extends StatelessWidget {
  const AnalysisRiskHeader({
    super.key,
    required this.riskLevel,
    required this.summary,
    this.reliability,
  });

  final RiskLevel riskLevel;
  final String summary;
  final ReliabilityLevel? reliability;

  @override
  Widget build(BuildContext context) {
    final reliability = this.reliability;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppAlertCard(level: riskLevel, title: summary),
        if (reliability != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppConfidenceIndicator(level: reliability),
        ],
      ],
    );
  }
}

/// 문서/문자에서 추출한 날짜 하나 — 납부기한/방문일 등([ImportantDate]).
class AnalysisDateCard extends StatelessWidget {
  const AnalysisDateCard({super.key, required this.date, this.onTap});

  final ImportantDate date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: AppInfoRow(
        label: date.label ?? _kindLabel(date.kind),
        value: _formatDate(date.date),
      ),
    );
  }

  static String _kindLabel(ImportantDateKind kind) => switch (kind) {
    ImportantDateKind.paymentDue => '납부 기한',
    ImportantDateKind.visit => '방문 날짜',
    ImportantDateKind.applicationPeriod => '신청 기간',
    ImportantDateKind.expiration => '만료일',
    ImportantDateKind.reservation => '예약 날짜',
    ImportantDateKind.other => '기타 일정',
  };

  static String _formatDate(DateTime date) => '${date.month}월 ${date.day}일';
}

/// AI 요약 문단. [maxLines] null(기본값)이면 잘라내지 않는다 — 결과 화면처럼
/// 짧게 유지해야 하는 곳(예: 4줄)에서만 지정한다.
class AnalysisSummary extends StatelessWidget {
  const AnalysisSummary({super.key, required this.summary, this.maxLines});

  final String summary;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSectionHeader(title: '요약'),
          Text(
            summary,
            style: AppTextStyles.bodyLarge,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ],
      ),
    );
  }
}

/// "해야 할 일" 체크리스트([ActionItem] 목록).
class AnalysisActionList extends StatelessWidget {
  const AnalysisActionList({super.key, required this.items, this.onChanged});

  final List<ActionItem> items;
  final ValueChanged<ActionItem>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSectionHeader(title: '해야 할 일'),
          for (final item in items)
            AppInfoRow(
              label: item.title,
              checked: item.completed,
              onCheckedChanged: onChanged == null
                  ? null
                  : (checked) =>
                        onChanged!(item.copyWith(completed: checked ?? false)),
            ),
        ],
      ),
    );
  }
}

/// 고지서 등 구조화 필드(`AnalysisResult.structuredFields`) 나열.
class AnalysisDetails extends StatelessWidget {
  const AnalysisDetails({super.key, required this.fields});

  final Map<String, Object?> fields;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSectionHeader(title: '상세 정보'),
          for (final entry in fields.entries)
            AppInfoRow(label: entry.key, value: '${entry.value}'),
        ],
      ),
    );
  }
}

/// AI가 확신하지 못해 사용자에게 되묻는 질문 하나
/// (`AnalysisResult.clarifyingQuestions`).
class AnalysisVoiceQuestion extends StatelessWidget {
  const AnalysisVoiceQuestion({
    super.key,
    required this.question,
    this.onAnswer,
  });

  final String question;
  final VoidCallback? onAnswer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // 행 전체를 탭 영역으로 넓힌다 — 아이콘만 탭 가능한 것보다 큰 터치
      // 영역을 제공한다(ui-principles.md 접근성, AnalysisActionChecklist와
      // 동일한 원칙).
      onTap: onAnswer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mic, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(question, style: AppTextStyles.bodyLarge)),
          if (onAnswer != null) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right),
          ],
        ],
      ),
    );
  }
}

/// 결과 화면 하단 "확인했어요" CTA — Senior Easy Mode는 [large]로 56px
/// 터치 영역을 쓴다.
class AnalysisConfirmButton extends StatelessWidget {
  const AnalysisConfirmButton({
    super.key,
    required this.onConfirm,
    this.label = '확인했어요',
    this.large = false,
    this.isLoading = false,
  });

  final VoidCallback? onConfirm;
  final String label;
  final bool large;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onConfirm,
      isLoading: isLoading,
      size: large ? AppButtonSize.large : AppButtonSize.standard,
    );
  }
}
