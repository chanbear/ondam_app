import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../domain/text_scale_level.dart';
import '../providers/accessibility_prefs_provider.dart';

/// 글자 크기/음성 안내 설정 컨트롤 — 온보딩 1단계와 설정 화면이 동일한 UI를
/// 공유한다(둘 다 같은 `accessibilityPrefsProvider`를 다룸).
class AccessibilitySettingsForm extends ConsumerWidget {
  const AccessibilitySettingsForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(accessibilityPrefsProvider);
    final notifier = ref.read(accessibilityPrefsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(title: '글자 크기'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final level in TextScaleLevel.values)
              ChoiceChip(
                label: Text(level.label),
                selected: prefs.textScale == level,
                onSelected: (_) => notifier.setTextScale(level),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: '음성 안내'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('화면 내용을 음성으로도 안내해드려요'),
          value: prefs.voiceGuideEnabled,
          onChanged: notifier.setVoiceGuideEnabled,
        ),
      ],
    );
  }
}
