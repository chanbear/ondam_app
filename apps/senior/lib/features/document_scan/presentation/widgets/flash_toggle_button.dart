import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../domain/entities/camera_flash_mode.dart';

/// Flash state control — always shows an icon AND a visible text label
/// (never icon-only, per ui-spec.md/ui-principles.md). Easy Mode gets a
/// larger touch target ("큰 버튼으로 제공, 현재 선택된 상태가 배경색/테두리로
/// 뚜렷이 구분") instead of a small icon toggle.
class FlashToggleButton extends StatelessWidget {
  const FlashToggleButton({
    super.key,
    required this.mode,
    required this.onTap,
    this.easyMode = false,
  });

  final CameraFlashMode mode;
  final VoidCallback onTap;
  final bool easyMode;

  IconData get _icon => switch (mode) {
    CameraFlashMode.off => Icons.flash_off,
    CameraFlashMode.on => Icons.flash_on,
    CameraFlashMode.auto => Icons.flash_auto,
  };

  @override
  Widget build(BuildContext context) {
    final minHeight = easyMode ? 56.0 : 44.0;

    return Semantics(
      button: true,
      label: mode.label,
      child: Material(
        // Camera-overlay scrim: no AppColors token exists yet for
        // "translucent overlay on a live camera feed" (a Figma-defined
        // value later) — `Colors.black` is Flutter's built-in constant,
        // not a hardcoded hex literal, and is a narrow, camera-only
        // exception, not a general design color choice.
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            constraints: BoxConstraints(
              minHeight: minHeight,
              minWidth: minHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: easyMode ? AppSpacing.lg : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: Colors.white, size: easyMode ? 28 : 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  mode.label,
                  style:
                      (easyMode
                              ? AppTextStyles.bodyLarge
                              : AppTextStyles.labelSmall)
                          .copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
