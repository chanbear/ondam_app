import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/text_scale_level.dart';
import '../../domain/voice_rate_level.dart';
import '../providers/accessibility_prefs_provider.dart';

/// 글자 크기/음성 안내 설정 컨트롤 — 온보딩 1단계와 설정 화면이 동일한 UI를
/// 공유한다(둘 다 같은 `accessibilityPrefsProvider`를 다룸).
class AccessibilitySettingsForm extends ConsumerWidget {
  const AccessibilitySettingsForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(accessibilityPrefsProvider);
    final notifier = ref.read(accessibilityPrefsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(title: l10n.textSizeTitle),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final level in TextScaleLevel.values)
              _AccessibilityChip(
                label: level.label,
                selected: prefs.textScale == level,
                onTap: () => notifier.setTextScale(level),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.voiceGuideTitle),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.voiceGuideDescription,
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              Switch(
                value: prefs.voiceGuideEnabled,
                onChanged: notifier.setVoiceGuideEnabled,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: l10n.voiceRateTitle),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final level in VoiceRateLevel.values)
              _AccessibilityChip(
                label: level.label,
                selected: prefs.voiceRate == level,
                onTap: () => notifier.setVoiceRate(level),
              ),
          ],
        ),
      ],
    );
  }
}

/// ui-prototype `.chip`/`.chip.active`(글자크기/음성속도 선택칩)와 같은
/// 시각 패턴 — 선택 시 `AppCard`의 `selected` variant(primary 테두리 +
/// primarySoft 배경)를 그대로 재사용해 새 색상 조합을 만들지 않는다.
class _AccessibilityChip extends StatelessWidget {
  const _AccessibilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: selected ? AppCardVariant.selected : AppCardVariant.normal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      child: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
