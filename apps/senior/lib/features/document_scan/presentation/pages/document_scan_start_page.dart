import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/voice_guide/voice_guide_scaffold.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/widgets/home_feature_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/captured_photo.dart';
import 'document_scan_camera_page.dart';
import 'document_scan_preview_page.dart';

/// ui-prototype `S("doc-start")` — 문서 분석 진입 화면. "사진 촬영하기"
/// (기존 카메라 흐름 그대로)와 "사진 불러오기"(갤러리에서 이미 있는 사진
/// 선택) 두 갈래를 제시하고, 촬영 정확도를 위한 팁 카드를 보여준다.
/// Easy Mode에서는 `HomeFeatureLargeButton`(홈의 `.easy-btn`과 동일 위젯,
/// 2026-08-30 core로 승격)으로 바꿔 두 버튼을 아이콘배지+큰라벨 형태로
/// 보여준다 — ui-prototype `E("doc-start")`의 easy-btn 두 개와 일치.
class DocumentScanStartPage extends ConsumerWidget {
  const DocumentScanStartPage({super.key});

  Future<void> _takePhoto(BuildContext context) async {
    final photo = await Navigator.of(context).push<CapturedPhoto>(
      MaterialPageRoute(builder: (_) => const DocumentScanCameraPage()),
    );
    if (photo == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentScanPreviewPage(photos: [photo]),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.photoLibraryUnavailableError)),
      );
      return;
    }
    if (picked == null || !context.mounted) return;
    final photo = CapturedPhoto(
      localPath: picked.path,
      capturedAt: DateTime.now(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentScanPreviewPage(photos: [photo]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    return VoiceGuideScaffold(
      title: l10n.documentScanStartTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (easyMode) ...[
            HomeFeatureLargeButton(
              item: HomeFeatureItem(
                icon: Icons.photo_camera,
                label: l10n.documentScanStartTakePhotoButton,
                iconColor: AppColors.primary,
                onTap: () => _takePhoto(context),
              ),
              showChevron: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            HomeFeatureLargeButton(
              item: HomeFeatureItem(
                icon: Icons.photo_library,
                label: l10n.documentScanStartPickPhotoButton,
                iconColor: AppColors.primary,
                onTap: () => _pickPhoto(context),
              ),
              showChevron: false,
            ),
          ] else ...[
            AppButton(
              label: l10n.documentScanStartTakePhotoButton,
              size: AppButtonSize.large,
              icon: Icons.photo_camera,
              onPressed: () => _takePhoto(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.documentScanStartPickPhotoButton,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.large,
              icon: Icons.photo_library,
              onPressed: () => _pickPhoto(context),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.documentScanStartTipTitle,
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '· ${l10n.documentScanStartTipLine1}\n'
                  '· ${l10n.documentScanStartTipLine2}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
