import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/text_scale_level.dart';
import '../../domain/voice_rate_level.dart';
import '../providers/accessibility_prefs_provider.dart';

/// [TextScaleLevel]/[VoiceRateLevel]은 domain 계층이라 l10n을 직접 참조할 수
/// 없다(architecture.md) — 값→문구 매핑은 여기, 이 위젯에서만 한다
/// (`GuardianLinkStatus`를 `guardian_list_page.dart`의 `_StatusBadge`가
/// 매핑하는 것과 같은 패턴).
String _textScaleLabel(AppLocalizations l10n, TextScaleLevel level) =>
    switch (level) {
      TextScaleLevel.normal => l10n.textScaleNormalLabel,
      TextScaleLevel.large => l10n.textScaleLargeLabel,
      TextScaleLevel.extraLarge => l10n.textScaleExtraLargeLabel,
    };

String _voiceRateLabel(AppLocalizations l10n, VoiceRateLevel level) =>
    switch (level) {
      VoiceRateLevel.normal => l10n.voiceRateNormalLabel,
      VoiceRateLevel.fast => l10n.voiceRateFastLabel,
      VoiceRateLevel.faster => l10n.voiceRateFasterLabel,
      VoiceRateLevel.fastest => l10n.voiceRateFastestLabel,
    };

String _textScaleDescription(AppLocalizations l10n, TextScaleLevel level) =>
    switch (level) {
      TextScaleLevel.normal => l10n.textScaleNormalDesc,
      TextScaleLevel.large => l10n.textScaleLargeDesc,
      TextScaleLevel.extraLarge => l10n.textScaleExtraLargeDesc,
    };

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
        Column(
          children: [
            for (final level in TextScaleLevel.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TextScaleOption(
                  label: _textScaleLabel(l10n, level),
                  description: _textScaleDescription(l10n, level),
                  scaleFactor: level.scaleFactor,
                  selected: prefs.textScale == level,
                  onTap: () => notifier.setTextScale(level),
                ),
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
                label: _voiceRateLabel(l10n, level),
                selected: prefs.voiceRate == level,
                onTap: () => notifier.setVoiceRate(level),
              ),
          ],
        ),
      ],
    );
  }
}

/// ui-prototype `.chip`/`.chip.active`(음성 속도 선택칩)와 같은 시각 패턴 —
/// 선택 시 `AppCard`의 `selected` variant(primary 테두리 + primarySoft
/// 배경)를 그대로 재사용해 새 색상 조합을 만들지 않는다.
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

/// ui-prototype `.textsize-option`(제목+설명+실제 크기 미리보기 "A")과 같은
/// 시각 패턴 — 글자 크기는 음성 속도와 달리 선택지 자체가 눈으로 확인해야
/// 하는 값이라(그 크기가 어떻게 보이는지) 일반 칩 대신 설명 문구와 실제
/// [scaleFactor]가 적용된 미리보기를 함께 보여준다.
class _TextScaleOption extends StatelessWidget {
  const _TextScaleOption({
    required this.label,
    required this.description,
    required this.scaleFactor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final double scaleFactor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        variant: selected ? AppCardVariant.selected : AppCardVariant.normal,
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.lg,
              height: AppSpacing.lg,
              child: selected
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: AppSpacing.md,
                        color: AppColors.surface,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'A',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: AppTextStyles.bodyLarge.fontSize! * scaleFactor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
