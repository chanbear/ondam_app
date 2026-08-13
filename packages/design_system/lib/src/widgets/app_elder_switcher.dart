import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Minimal info about an elder for display in [AppElderSwitcher] — name
/// only, per the personal-data-minimization principle (ui-principles.md
/// Guardian 5). The real domain entity lives in the `connection` feature
/// once it exists (Phase 5); this is just what the switcher needs to render.
class ElderSummary {
  const ElderSummary({required this.id, required this.name});

  final String id;
  final String name;
}

/// Guardian 1:N elder selector (ui-information-architecture.md "Guardian
/// 1:N 어르신 선택 구조", Decision 2). With exactly one elder, shows the
/// name only — no picker UI. With two or more, shows a tappable label that
/// opens a bottom sheet picker.
class AppElderSwitcher extends StatelessWidget {
  const AppElderSwitcher({
    super.key,
    required this.elders,
    required this.selectedElderId,
    required this.onSelect,
  });

  final List<ElderSummary> elders;
  final String? selectedElderId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (elders.isEmpty) return const SizedBox.shrink();

    if (elders.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(elders.first.name, style: AppTextStyles.titleMedium),
      );
    }

    final selected = elders.firstWhere(
      (elder) => elder.id == selectedElderId,
      orElse: () => elders.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Semantics(
        button: true,
        label: '어르신 선택, 현재 ${selected.name}',
        child: InkWell(
          onTap: () => _openPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selected.name, style: AppTextStyles.titleMedium),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final elder in elders)
              ListTile(
                title: Text(elder.name),
                selected: elder.id == selectedElderId,
                onTap: () {
                  onSelect(elder.id);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
