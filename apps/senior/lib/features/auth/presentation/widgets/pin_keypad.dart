import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Large numeric keypad for PIN entry — sized for elderly users (the Senior
/// app's entire audience, not gated behind the easy-mode toggle, per
/// technical-decisions.md UI 결정: 쉬운 모드 is the app's core UX baseline).
/// Feature-local: only used within this feature's PIN pages, so it stays
/// out of `ondam_design_system` per ui-design.md ("두 개 이상의 feature가
/// 공유하는 위젯만 core/design_system에 둔다").
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.pinLength,
    required this.enteredLength,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final int pinLength;
  final int enteredLength;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  static const double _keySize = 76;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PinDots(filled: enteredLength, total: pinLength),
        const SizedBox(height: AppSpacing.xl),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final digit in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: _KeypadButton(
                      label: digit,
                      onTap: enabled ? () => onDigit(digit) : null,
                    ),
                  ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: _keySize + AppSpacing.sm * 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: _KeypadButton(
                label: '0',
                onTap: enabled ? () => onDigit('0') : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: _KeypadButton(
                icon: Icons.backspace_outlined,
                semanticLabel: AppLocalizations.of(
                  context,
                )!.pinKeypadClearLabel,
                onTap: enabled ? onBackspace : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? AppColors.primary : AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({this.label, this.icon, this.semanticLabel, this.onTap});

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = label != null
        ? Text(label!, style: AppTextStyles.headlineMedium)
        : Icon(icon, size: 28, color: AppColors.textPrimary);

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: PinKeypad._keySize,
            height: PinKeypad._keySize,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
