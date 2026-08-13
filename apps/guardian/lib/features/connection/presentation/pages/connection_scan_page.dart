import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/scan_connection_notifier.dart';

/// 보호자 측 QR 스캔 화면(technical-decisions.md §1-6 v9,
/// ui-information-architecture.md "Guardian: 신규 연결 — QR 스캔"). 스캔
/// 성공은 연결 완료가 아니라 요청 생성일 뿐이라는 점을 화면 문구로 항상
/// 알린다.
class ConnectionScanPage extends ConsumerStatefulWidget {
  const ConnectionScanPage({super.key});

  @override
  ConsumerState<ConnectionScanPage> createState() => _ConnectionScanPageState();
}

class _ConnectionScanPageState extends ConsumerState<ConnectionScanPage> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final token = barcodes.first.rawValue;
    if (token == null || token.isEmpty) return;
    _handled = true;
    ref.read(scanConnectionProvider.notifier).redeem(token);
  }

  void _resetForRetry() {
    setState(() => _handled = false);
    ref.invalidate(scanConnectionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanConnectionProvider);

    return AppScaffold(
      title: '어르신 연결하기',
      onBack: () => Navigator.of(context).pop(),
      body: state.when(
        loading: () => const AppLoading(message: '연결 요청을 보내고 있어요'),
        error: (error, _) => _ScanErrorView(
          failure: error is Failure ? error : const UnknownFailure(),
          onRetry: _resetForRetry,
        ),
        data: (link) => link == null
            ? _ScannerView(controller: _controller, onDetect: _onDetect)
            : _ScanSuccessView(onDone: () => Navigator.of(context).pop()),
      ),
    );
  }
}

class _ScannerView extends StatelessWidget {
  const _ScannerView({required this.controller, required this.onDetect});

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '어르신 화면에 표시된 QR 코드를 비춰주세요',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: MobileScanner(
              controller: controller,
              onDetect: onDetect,
              errorBuilder: (context, error) =>
                  _CameraPermissionDeniedView(error: error),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraPermissionDeniedView extends StatelessWidget {
  const _CameraPermissionDeniedView({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 40),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '카메라 권한이 필요해요',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: '설정으로 이동', onPressed: openAppSettings),
          ],
        ),
      ),
    );
  }
}

class _ScanErrorView extends StatelessWidget {
  const _ScanErrorView({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppError(message: failure.message, onRetry: onRetry);
  }
}

class _ScanSuccessView extends StatelessWidget {
  const _ScanSuccessView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '연결 요청을 보냈어요',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '어르신이 요청을 수락하면 연결이 완료돼요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: '확인',
              size: AppButtonSize.large,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
