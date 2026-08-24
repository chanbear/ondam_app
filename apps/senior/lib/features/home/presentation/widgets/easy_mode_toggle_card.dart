import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 홈 화면에서 쉬운 모드를 바로 켜고 끌 수 있는 카드(ONDAM 2.0 요구사항
/// 33) — 더보기 → 설정의 기존 토글은 그대로 두고, 여기 하나를 더 둔다.
/// 작은 Switch만 두지 않고 현재 상태를 문장으로도 보여준다(고령자 대상
/// 접근성 원칙). 일반 모드/쉬운 모드 홈 화면 모두에서 동일하게 쓰인다 —
/// `easyModeProvider`(기존 상태 저장 구조)를 그대로 재사용한다.
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
      child: Material(
        color: easyMode
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () => ref.read(easyModeProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.easyModeTitle,
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        easyMode
                            ? l10n.easyModeOnDescription
                            : l10n.easyModeOffState,
                        style: AppTextStyles.bodyMedium.copyWith(
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
      ),
    );
  }
}
