import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/captured_photo.dart';
import '../widgets/local_photo_image.dart';
import 'document_scan_camera_page.dart';
import 'document_scan_result_page.dart';

/// 촬영 결과 확인 — ONDAM 2.0 요구사항 11(다중 문서 촬영)에 맞춰 여러 장을
/// 모을 수 있는 화면으로 재구성했다. [photos]는 시작값일 뿐, 이 화면
/// 안에서 계속 늘어나거나 줄어들 수 있는 로컬 상태다(화면 하나에서만
/// 의미 있는 상태 — riverpod.md에 따라 전역 Provider로 만들지 않는다).
///
/// "재촬영"은 기존과 동일하게 전체를 버리고 카메라로 돌아간다(단일 문서
/// 흐름의 기존 동작 그대로 — 사진 1장뿐일 때는 "다시 찍기"와 동일하다).
/// "추가 촬영"이 새로 생긴 버튼으로, 기존 사진을 유지한 채 카메라를 다시
/// 열어 목록에 追加한다.
class DocumentScanPreviewPage extends StatefulWidget {
  const DocumentScanPreviewPage({super.key, required this.photos})
    : assert(photos.length > 0, '촬영된 사진이 최소 1장 있어야 미리보기를 열 수 있다');

  final List<CapturedPhoto> photos;

  @override
  State<DocumentScanPreviewPage> createState() =>
      _DocumentScanPreviewPageState();
}

class _DocumentScanPreviewPageState extends State<DocumentScanPreviewPage> {
  late List<CapturedPhoto> _photos = List.of(widget.photos);

  Future<void> _addAnother() async {
    final photo = await Navigator.of(context).push<CapturedPhoto>(
      MaterialPageRoute(builder: (_) => const DocumentScanCameraPage()),
    );
    if (photo == null || !mounted) return;
    setState(() => _photos = [..._photos, photo]);
  }

  void _remove(int index) {
    setState(() => _photos = [..._photos]..removeAt(index));
  }

  void _analyze() {
    // 빈 목록으로는 분석 요청을 만들 수 없다(요구사항 11 최소 요구사항).
    if (_photos.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentScanResultPage(photos: _photos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final easyMode = ref.watch(easyModeProvider);
        final l10n = AppLocalizations.of(context)!;

        return AppScaffold(
          title: l10n.scanPreviewTitle,
          onBack: () => Navigator.of(context).pop(),
          backLabel: l10n.retakeLabel,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ui-prototype `doc-multi`: "N장 촬영했어요" 헤드라인 + 매수
              // 전용 pill을 카드 하나로 묶는다(위험도 배지가 아닌 매수
              // 표시라는 prototype의 2026-08-27 수정 의도 그대로).
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.scannedDocumentsCount(_photos.length),
                      style: AppTextStyles.titleMedium,
                    ),
                    _PhotoCountBadge(count: _photos.length),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _PhotoThumbnailList(
                  photos: _photos,
                  easyMode: easyMode,
                  onRemove: _remove,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.addAnotherPhotoButton,
                icon: Icons.add_a_photo_outlined,
                variant: AppButtonVariant.secondary,
                size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
                onPressed: _addAnother,
              ),
              const SizedBox(height: AppSpacing.lg),
              // "재촬영"은 헤더의 뒤로가기 링크(backLabel)가 이미 같은 동작을
              // 제공한다 — 여기서는 "분석하기"만 전체 너비 주 CTA로 명확하게
              // 보여준다(prototype `documentPreview()`의 fixedBottom과 동일한
              // 단일 CTA 구조).
              AppButton(
                label: l10n.analyzeButton,
                size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
                onPressed: _photos.isEmpty ? null : _analyze,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 매수 pill — `EasyAnalysisResultView`의 종류 태그와 동일한 패턴
/// (`AppColors.primarySoft` 배경 + `AppRadius.full`)을 재사용한다.
class _PhotoCountBadge extends StatelessWidget {
  const _PhotoCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        AppLocalizations.of(context)!.photoCountBadge(count),
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _PhotoThumbnailList extends StatelessWidget {
  const _PhotoThumbnailList({
    required this.photos,
    required this.onRemove,
    this.easyMode = false,
  });

  final List<CapturedPhoto> photos;
  final ValueChanged<int> onRemove;
  final bool easyMode;

  @override
  Widget build(BuildContext context) {
    // Easy Mode는 한 번에 보이는 정보량을 줄인다는 원칙(ui-principles.md)에
    // 따라 썸네일을 더 크게 보여준다(스크롤로 넘기는 개수는 줄고, 하나하나는
    // 더 뚜렷해진다) — 목록/삭제/추가 동작 자체는 바뀌지 않는다.
    final width = easyMode ? 150.0 : 120.0;
    final height = easyMode ? 200.0 : 160.0;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: photos.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final photo = photos[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: buildLocalPhotoImage(
                photo.localPath,
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
            ),
            // 각 사진이 몇 번째인지 명확히 — prototype `documentPreview()`의
            // "문서 N" 라벨과 동일.
            Positioned(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  AppLocalizations.of(context)!.documentIndexLabel(index + 1),
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                button: true,
                label: AppLocalizations.of(
                  context,
                )!.deletePhotoAtIndexLabel(index + 1),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: ValueKey('remove_photo_$index'),
                    customBorder: const CircleBorder(),
                    onTap: photos.length > 1 ? () => onRemove(index) : null,
                    // ui-design.md "탭 가능한 요소는 최소 44x44 논리 픽셀
                    // 터치 영역을 확보한다" — 아이콘(18) + 패딩만으로는
                    // 26x26에 그쳐 기준에 못 미쳤다(ONDAM 2.0 PHASE 31에서
                    // 발견). AppSpacing.md 패딩으로 50x50을 확보한다. Easy
                    // Mode는 AppTouch.easy(56)에 맞춰 한 단계 더 키운다.
                    child: Padding(
                      padding: EdgeInsets.all(
                        easyMode ? AppSpacing.lg : AppSpacing.md,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: easyMode ? 22 : 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
