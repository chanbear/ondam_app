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
    required this.onClose,
    this.easyMode = false,
  });

  final ValueChanged<CapturedPhoto> onCaptured;

  /// 닫기(뒤로가기) — 몰입형 카메라 화면이라 표준 AppHeader 대신 이
  /// 위젯 안에서 자체 닫기 버튼을 그린다(ui-prototype `doc-camera` 상단
  /// 바 구조).
  final VoidCallback onClose;
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

  // CameraFlashMode.on은 "문서를 비추는 지속 조명"(라이트) 의도다 —
  // FlashMode.always는 촬영 순간에만 잠깐 터지는 카메라 플래시라 라이트를
  // 켜도 화면상 아무 변화가 없어 "안 켜진다"는 버그로 보였다. 계속 켜져
  // 있는 FlashMode.torch가 맞는 매핑이다.
  camera_pkg.FlashMode _toPlatformFlashMode(CameraFlashMode mode) =>
      switch (mode) {
        CameraFlashMode.off => camera_pkg.FlashMode.off,
        CameraFlashMode.on => camera_pkg.FlashMode.torch,
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
        // ui-prototype `doc-camera` — 촬영 대상을 정렬하도록 돕는 점선
        // 프레임 가이드(시각 안내일 뿐, 실제 크롭/검증 로직과는 무관).
        const _DashedFrameGuide(),
        // 상단 바 — ui-prototype `doc-camera`: 닫기 버튼 + 촬영 가이드 문구가
        // 제목 자리를 대신하고, 플래시가 오른쪽 끝에 온다(별도 헤더 없이
        // 카메라 화면 자체가 이 바를 그린다).
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Row(
            children: [
              _CloseButton(onTap: widget.onClose),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.documentFrameGuideMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
              FlashToggleButton(
                mode: _flashMode,
                easyMode: widget.easyMode,
                onTap: _toggleFlash,
              ),
            ],
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

/// 카메라 화면 닫기 — [FlashToggleButton]과 같은 반투명 검정 원형 배경
/// 패턴을 재사용해(카메라 오버레이 전용, `Colors.black` 예외는 그 위젯의
/// 기존 결정과 동일한 이유) 44x44 이상의 터치 영역을 확보한다.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.closeCameraButtonLabel,
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Padding(
            // ui-design.md 최소 44x44 터치 영역 — 아이콘(24) + smMd(12) 패딩
            // 양쪽으로 48x48을 확보한다([FlashToggleButton]과 동일한 근거).
            padding: EdgeInsets.all(AppSpacing.smMd),
            child: Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ),
      ),
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
      child: Container(
        // ui-prototype `doc-camera` — 셔터 링을 앱 accent(primary) 색으로
        // 둬 브랜드 톤을 유지한다(흰 원 + 6px primary 테두리, 아이콘 없음).
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.primary, width: 6),
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: capturing ? null : onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 64,
              height: 64,
              child: capturing
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// ui-prototype `doc-camera` — 문서 정렬용 점선 프레임(2px dashed 흰색
/// 반투명, 둥근 사각형). 시각 가이드일 뿐 크롭/검증에 관여하지 않는다.
class _DashedFrameGuide extends StatelessWidget {
  const _DashedFrameGuide();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85,
          heightFactor: 0.55,
          child: CustomPaint(painter: _DashedRRectPainter()),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.lg),
    );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) => false;
}
