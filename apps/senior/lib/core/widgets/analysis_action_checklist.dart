import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../l10n/generated/app_localizations.dart';

/// ONDAM 2.0 결과 화면의 "해야 할 일" 체크리스트. 완료 상태는 이 화면을
/// 벗어나면(재진입/재분석) 사라지는 세션 내 로컬 상태다 — DB/서버에
/// 저장하지 않는다(Phase 4 §9). [items]가 비어있으면 아무것도 그리지
/// 않는다. 각 행 전체를 탭 영역으로 넓혀 체크박스만 누를 수 있는 것보다
/// 큰 터치 영역을 제공한다(ui-principles.md 접근성).
class AnalysisActionChecklist extends StatelessWidget {
  const AnalysisActionChecklist({
    super.key,
    required this.items,
    required this.onToggle,
  });

  final List<ActionItem> items;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: AppLocalizations.of(context)!.actionChecklistTitle,
        ),
        for (var i = 0; i < items.length; i++)
          MergeSemantics(
            child: InkWell(
              onTap: () => onToggle(i),
              child: AppInfoRow(
                label: items[i].title,
                checked: items[i].completed,
                onCheckedChanged: (_) => onToggle(i),
              ),
            ),
          ),
      ],
    );
  }
}
