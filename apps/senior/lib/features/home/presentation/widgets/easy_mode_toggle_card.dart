import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 홈 화면에서 쉬운 모드를 바로 켜고 끌 수 있는 행(ONDAM 2.0 요구사항 33)
/// — 더보기 → 설정의 기존 토글은 그대로 두고, 여기 하나를 더 둔다. 작은
/// Switch만 두지 않고 현재 상태를 문장으로도 보여준다(고령자 대상 접근성
/// 원칙). 일반 모드/쉬운 모드 홈 화면 모두에서 동일하게 쓰인다 —
/// `easyModeProvider`(기존 상태 저장 구조)를 그대로 재사용한다.
///
/// 박스형 카드가 아니라 아이콘 없는 한 줄 + 하단 구분선으로 단순화했다.
/// on/off도 배경색 대신 Switch 위치만으로 구분한다. 설명 문구는
/// ui-prototype `S("home")`의 토글 행처럼 on/off 상태와 무관하게 항상
/// 같은 한 문장을 보여준다(2026-08-30 정렬 — 이전엔 꺼짐 상태일 때
/// "꺼짐"이라는 단어만 보여줬던 것을 고쳤다).
class EasyModeToggleCard extends ConsumerWidget {
  const EasyModeToggleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(easyModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      toggled: easyMode,
      label: l10n.easyModeToggleSemanticLabel(
        easyMode ? l10n.easyModeOnState : l10n.easyModeOffState,
      ),
      child: InkWell(
        onTap: () => ref.read(easyModeProvider.notifier).toggle(),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTouch.standard),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.easyModeTitle, style: AppTextStyles.bodyLarge),
                    Text(
                      l10n.easyModeDescription,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: Switch(
                  value: easyMode,
                  onChanged: (_) =>
                      ref.read(easyModeProvider.notifier).toggle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
