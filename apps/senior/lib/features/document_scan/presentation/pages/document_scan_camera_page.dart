import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../domain/entities/camera_permission_status.dart';
import '../providers/camera_permission_provider.dart';
import '../widgets/camera_preview_view.dart';

/// 문서 촬영 진입점 — 권한 상태별로 명확히 다른 화면을 보여준다(허용/거부/
/// 영구거부/제한). 허용 상태에서만 실제 카메라 프리뷰를 그린다.
///
/// ONDAM 2.0 요구사항 11(다중 문서 촬영) — 이 화면은 촬영 한 장을 찍고
/// 곧장 [Navigator.pop]으로 호출부에 돌려준다(더 이상 스스로 미리보기를
/// push하지 않는다). "한 번 촬영해서 돌려준다"는 책임 하나만 지므로,
/// 처음 진입(홈 탭)이든 미리보기 화면의 "추가 촬영"이든 동일하게 재사용할
/// 수 있다 — 여러 장을 모으는 로직은 호출부(`document_scan_preview_page.dart`)
/// 가 갖는다.
class DocumentScanCameraPage extends ConsumerWidget {
  const DocumentScanCameraPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(easyModeProvider);
    final permissionAsync = ref.watch(cameraPermissionProvider);

    return AppScaffold(
      title: '문서 촬영',
      onBack: () => Navigator.of(context).pop(),
      padding: EdgeInsets.zero,
      body: permissionAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: '카메라 권한을 확인하지 못했어요.',
          onRetry: () => ref.invalidate(cameraPermissionProvider),
        ),
        data: (status) {
          return switch (status) {
            CameraPermissionStatus.granted => CameraPreviewView(
              easyMode: easyMode,
              onCaptured: (photo) => Navigator.of(context).pop(photo),
            ),
            CameraPermissionStatus.denied => _PermissionRequestView(
              easyMode: easyMode,
              onRequest: () =>
                  ref.read(cameraPermissionProvider.notifier).request(),
            ),
            CameraPermissionStatus.permanentlyDenied ||
            CameraPermissionStatus.restricted => const _PermissionBlockedView(),
          };
        },
      ),
    );
  }
}

class _PermissionRequestView extends StatelessWidget {
  const _PermissionRequestView({
    required this.easyMode,
    required this.onRequest,
  });

  final bool easyMode;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            '문서와 문자를 촬영해 분석하려면\n카메라 접근을 허용해주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: '카메라 권한 허용하기',
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: onRequest,
          ),
        ],
      ),
    );
  }
}

class _PermissionBlockedView extends StatelessWidget {
  const _PermissionBlockedView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            '카메라 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: '설정 열기', onPressed: openAppSettings),
        ],
      ),
    );
  }
}
