import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 기록 탭 — `analysis`/`schedule` feature에 아직 domain/data 계층이 없어
/// 항상 빈 상태다. 문구는 기존 온담앱에서 확인된 톤을 그대로 유지
/// (`ui-spec.md` "Empty State").
class RecordsTabPage extends StatelessWidget {
  const RecordsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: AppSectionHeader(title: '기록'),
        ),
        const Expanded(
          child: AppEmptyState(
            message: '아직 분석한 기록이 없습니다.\n문서 찍기나 문자 보기를 이용해보세요.',
          ),
        ),
      ],
    );
  }
}
