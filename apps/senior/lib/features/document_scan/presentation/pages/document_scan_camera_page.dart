import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    // 촬영 화면(granted)만 카메라 프리뷰가 화면 전체를 채우는 몰입형
    // 레이아웃이라 표준 밝은 AppHeader를 띄우지 않는다(ui-prototype
    // `doc-camera`: 어두운 배경 위에 닫기 버튼+안내 문구가 자체 오버레이로
    // 함께 있음, `CameraPreviewView`가 그 오버레이를 그린다). 권한 요청/차단
    // 화면은 카메라가 없는 단순 안내 화면이라 다른 화면들과 같은 표준
    // AppHeader를 그대로 쓴다.
    final showsCameraPreview = permissionAsync.maybeWhen(
      data: (status) => status == CameraPermissionStatus.granted,
      orElse: () => false,
    );

    return AppScaffold(
      title: showsCameraPreview ? null : l10n.documentScanTitle,
      onBack: showsCameraPreview ? null : () => Navigator.of(context).pop(),
      padding: EdgeInsets.zero,
      body: permissionAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: l10n.cameraPermissionCheckError,
          onRetry: () => ref.invalidate(cameraPermissionProvider),
        ),
        data: (status) {
          return switch (status) {
            CameraPermissionStatus.granted => CameraPreviewView(
              easyMode: easyMode,
              onCaptured: (photo) => Navigator.of(context).pop(photo),
              onClose: () => Navigator.of(context).pop(),
            ),
            CameraPermissionStatus.denied => _PermissionRequestView(
              easyMode: easyMode,
              onRequest: () =>
                  ref.read(cameraPermissionProvider.notifier).request(),
            ),
            CameraPermissionStatus.permanentlyDenied ||
            CameraPermissionStatus.restricted => _PermissionBlockedView(
              easyMode: easyMode,
            ),
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
            AppLocalizations.of(context)!.cameraPermissionRequestMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: AppLocalizations.of(context)!.cameraPermissionRequestButton,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: onRequest,
          ),
        ],
      ),
    );
  }
}

class _PermissionBlockedView extends StatelessWidget {
  const _PermissionBlockedView({required this.easyMode});

  final bool easyMode;

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
            AppLocalizations.of(context)!.cameraPermissionBlockedMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: AppLocalizations.of(context)!.openSettingsButton,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: openAppSettings,
          ),
        ],
      ),
    );
  }
}
