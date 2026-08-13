import 'package:camera/camera.dart' as camera_pkg;
import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

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
        if (mounted) setState(() => _initError = '사용 가능한 카메라가 없어요.');
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
      if (mounted) setState(() => _initError = '카메라를 시작하지 못했어요.');
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이 기기에서는 플래시를 사용할 수 없어요.')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('촬영에 실패했어요. 다시 시도해주세요.')));
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
      return const AppLoading(message: '카메라를 준비하고 있어요');
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        camera_pkg.CameraPreview(controller),
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
      label: '촬영하기',
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
