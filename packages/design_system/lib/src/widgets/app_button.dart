import 'package:flutter/material.dart';

import '../tokens/app_text_styles.dart';

/// `standard` is the general-purpose default (48dp min height — Material's
/// accessibility floor). `large` is for Easy Mode / high-stakes CTAs
/// (56dp+, larger label) — see ui-principles.md "큰 터치 영역".
enum AppButtonSize { standard, large }

/// Shared primary button — use instead of raw ElevatedButton so styling stays
/// consistent across features (styling itself comes from AppTheme).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.standard,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final isLarge = size == AppButtonSize.large;
    final minHeight = isLarge ? 56.0 : 48.0;
    final spinnerSize = isLarge ? 24.0 : 20.0;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, minHeight),
        textStyle: isLarge ? AppTextStyles.titleMedium : null,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
