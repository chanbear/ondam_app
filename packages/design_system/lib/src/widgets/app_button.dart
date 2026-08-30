import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import '../tokens/app_touch.dart';

/// `standard` is the general-purpose default (48dp min height — Material's
/// accessibility floor). `large` is for Easy Mode / high-stakes CTAs
/// (56dp+, larger label) — see ui-principles.md "큰 터치 영역".
enum AppButtonSize { standard, large }

/// Visual weight — mirrors the Phase 42-approved HTML prototype's
/// `.btn-primary`/`.btn-secondary`/`.btn-danger`/`.btn-ghost` (`ui-spec.md`).
/// `destructive` uses a soft (tonal) error fill, not a solid one, matching
/// the prototype's `--color-danger-bg`/`--color-danger` pair. `emergency`
/// is a solid fill using the dedicated SOS-only `AppColors.emergency` token
/// (separate from `error`) — `ui-prototype`'s `T.button({variant:"emergency"})`.
enum AppButtonVariant { primary, secondary, destructive, text, emergency }

/// Shared button — use instead of raw ElevatedButton/OutlinedButton/TextButton
/// so styling stays consistent across features (colors come from AppTheme).
/// Supports the shared minimum states (default/pressed/disabled/loading) —
/// pressed/disabled come from Flutter's built-in Material state layers,
/// [isLoading] disables the button and swaps its label for a spinner.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.standard,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final AppButtonVariant variant;

  /// 선택적 leading icon — 텍스트 없이 아이콘만 쓰지 않는다는 원칙은 그대로
  /// 유지된다(라벨은 항상 필수). null(기본값)이면 텍스트만 보여준다.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isLarge = size == AppButtonSize.large;
    final minHeight = isLarge ? AppTouch.easy : AppTouch.standard;
    final spinnerSize = isLarge ? 24.0 : 20.0;
    final textStyle = isLarge ? AppTextStyles.titleMedium : null;
    final onPressedOrNull = isLoading ? null : onPressed;

    final spinner = SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: variant == AppButtonVariant.primary
            ? AppColors.surface
            : AppColors.primary,
      ),
    );
    final icon = this.icon;
    final label = Text(this.label);
    final child = switch ((isLoading, icon)) {
      (true, _) => spinner,
      (false, null) => label,
      (false, final icon?) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          label,
        ],
      ),
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, minHeight),
          shape: shape,
          textStyle: textStyle,
        ),
        onPressed: onPressedOrNull,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, minHeight),
          shape: shape,
          side: const BorderSide(color: AppColors.primary, width: 2),
          foregroundColor: AppColors.primary,
          textStyle: textStyle,
        ),
        onPressed: onPressedOrNull,
        child: child,
      ),
      AppButtonVariant.destructive => FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minHeight),
          shape: shape,
          backgroundColor: AppColors.errorSoft,
          foregroundColor: AppColors.error,
          textStyle: textStyle,
        ),
        onPressed: onPressedOrNull,
        child: child,
      ),
      AppButtonVariant.emergency => FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minHeight),
          shape: shape,
          backgroundColor: AppColors.emergency,
          foregroundColor: AppColors.surface,
          textStyle: textStyle,
        ),
        onPressed: onPressedOrNull,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        style: TextButton.styleFrom(
          minimumSize: Size(double.infinity, minHeight),
          shape: shape,
          foregroundColor: AppColors.textSecondary,
          textStyle: textStyle ?? AppTextStyles.bodyLarge,
        ),
        onPressed: onPressedOrNull,
        child: child,
      ),
    };
  }
}
