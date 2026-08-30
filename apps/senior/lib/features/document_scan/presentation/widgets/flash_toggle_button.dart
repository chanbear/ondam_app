import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/camera_flash_mode.dart';

/// [CameraFlashMode]는 domain 계층이라 l10n을 직접 참조할 수 없다
/// (architecture.md) — 값→문구 매핑은 이 위젯에서만 한다
/// (`accessibility_settings_form.dart`의 `_textScaleLabel`과 같은 패턴).
String _flashModeLabel(AppLocalizations l10n, CameraFlashMode mode) =>
    switch (mode) {
      CameraFlashMode.off => l10n.flashOffLabel,
      CameraFlashMode.on => l10n.flashOnLabel,
      CameraFlashMode.auto => l10n.flashAutoLabel,
    };

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
    final label = _flashModeLabel(AppLocalizations.of(context)!, mode);

    return Semantics(
      button: true,
      label: label,
      // 실기기 확인: 이게 없으면 안쪽 Text가 별도 시맨틱 노드로 잡혀
      // 스크린리더가 "플래시 꺼짐, 플래시 꺼짐"처럼 같은 문구를 두 번
      // 읽는다 — 바깥 Semantics의 label 하나만 읽히도록 안쪽을 제외한다.
      excludeSemantics: true,
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
                  label,
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
