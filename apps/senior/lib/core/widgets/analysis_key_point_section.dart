import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

const _keyPointMaxLength = 60;

/// summary에서 첫 문장만 뽑아 "주요 내용"으로 짧게 보여준다 — 새 문장을
/// 만들지 않고 AI가 이미 작성한 summary의 앞부분만 그대로 사용한다(ONDAM
/// 2.0 요구사항 14/23: 긴 요약을 먼저 보여주지 않고 주요 내용을 짧게 먼저
/// 표시). 한국어 문장 종결 어미(다/요) 뒤 공백을 문장 경계로 보는 간단한
/// 휴리스틱이라 완벽하지 않다 — ponytail: 문장 경계를 정확히 파악하려면
/// 자연어 처리가 필요하지만, 이 용도(짧은 미리보기)에는 과함.
String extractKeyPoint(String summary) {
  final trimmed = summary.trim();
  if (trimmed.isEmpty) return trimmed;

  final match = RegExp(r'[.!?다요]\s').firstMatch(trimmed);
  final sentence = match != null
      ? trimmed.substring(0, match.end - 1)
      : trimmed;

  if (sentence.length <= _keyPointMaxLength) return sentence;
  return '${sentence.substring(0, _keyPointMaxLength).trimRight()}...';
}

/// ONDAM 2.0 결과 화면의 "주요 내용" 섹션 — AI 요약(최대 4줄, 아래 별도
/// 섹션)과 구분되는, 아주 짧은 한 줄 하이라이트. [summary]가 비어있으면
/// 아무것도 그리지 않는다.
class AnalysisKeyPointSection extends StatelessWidget {
  const AnalysisKeyPointSection({super.key, required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final keyPoint = extractKeyPoint(summary);
    if (keyPoint.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '주요 내용'),
        Text(keyPoint, style: AppTextStyles.titleMedium),
      ],
    );
  }
}
