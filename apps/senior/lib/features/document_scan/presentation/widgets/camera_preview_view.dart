import 'package:camera/camera.dart' as camera_pkg;
import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/camera_flash_mode.dart';
import '../../domain/entities/captured_photo.dart';
import 'flash_toggle_button.dart';

/// Owns the live `CameraController` directly — a hardware/UI-bound,
/// disposable controller is exactly the case flutter.md carves out for
/// local `StatefulWidget` state (like `AnimationController`), not a
/// Repository-wrapped resource (see `domain/repositories/camera_repository.dart`
/// for why). This is the ONLY file in the feature that imports
/// `package:camera`.
class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView({
    super.key,
    required this.onCaptured,
    this.easyMode = false,
  });

  final ValueChanged<CapturedPhoto> onCaptured;
  final bool easyMode;

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  camera_pkg.CameraController? _controller;
  CameraFlashMode _flashMode = CameraFlashMode.off;
  String? _initError;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cameras = await camera_pkg.availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(
            () => _initError = AppLocalizations.of(
              context,
            )!.noCameraAvailableError,
          );
        }
        return;
      }
      final controller = camera_pkg.CameraController(
        cameras.first,
        camera_pkg.ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(_toPlatformFlashMode(_flashMode));
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _initError = AppLocalizations.of(context)!.cameraStartError,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  camera_pkg.FlashMode _toPlatformFlashMode(CameraFlashMode mode) =>
      switch (mode) {
        CameraFlashMode.off => camera_pkg.FlashMode.off,
        CameraFlashMode.on => camera_pkg.FlashMode.always,
        CameraFlashMode.auto => camera_pkg.FlashMode.auto,
      };

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode.next;
    try {
      await controller.setFlashMode(_toPlatformFlashMode(next));
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.flashUnavailableError),
        ),
      );
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      widget.onCaptured(
        CapturedPhoto(localPath: file.path, capturedAt: DateTime.now()),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.captureFailedError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initError = _initError;
    if (initError != null) {
      return AppError(
        message: initError,
        onRetry: () {
          setState(() => _initError = null);
          _initialize();
        },
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return AppLoading(
        message: AppLocalizations.of(context)!.cameraPreparingMessage,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        camera_pkg.CameraPreview(controller),
        // 촬영 가이드 문구 — HTML prototype `documentCamera()`와 동일한 안내
        // ("문서를 화면 안에 맞춰주세요"). 실제 촬영 로직에는 관여하지 않는
        // 순수 안내 오버레이다.
        Positioned(
          // 우상단 FlashToggleButton(최대 56px 높이 + 상단 여백)과 겹치지
          // 않도록 그 아래에 둔다.
          top: AppSpacing.xxl + AppSpacing.xl,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Text(
            AppLocalizations.of(context)!.documentFrameGuideMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: FlashToggleButton(
            mode: _flashMode,
            easyMode: widget.easyMode,
            onTap: _toggleFlash,
          ),
        ),
        Positioned(
          bottom: AppSpacing.xl,
          left: 0,
          right: 0,
          child: Center(
            child: _ShutterButton(capturing: _capturing, onTap: _capture),
          ),
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.capturing, required this.onTap});

  final bool capturing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.captureButtonLabel,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: capturing ? null : onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 76,
            height: 76,
            child: capturing
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.camera_alt,
                    color: AppColors.textPrimary,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}
