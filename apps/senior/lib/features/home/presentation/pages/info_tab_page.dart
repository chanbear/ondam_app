import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 정보 탭 — `welfare_center`/`info` feature에 아직 domain/data 계층이 없어
/// 실제 데이터를 보여줄 수 없다. Mock으로 채우지 않고 정직한 빈 상태로 둔다.
class InfoTabPage extends StatelessWidget {
  const InfoTabPage({super.key});

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
          child: AppSectionHeader(title: '정보'),
        ),
        const Expanded(
          child: AppEmptyState(message: '아직 준비된 정보가 없어요. 곧 맞춤 정보를 보여드릴게요.'),
        ),
      ],
    );
  }
}
