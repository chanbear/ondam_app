import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../domain/entities/captured_photo.dart';
import 'document_scan_result_page.dart';

/// 촬영 결과 확인 — 재촬영(뒤로가기, 카메라 화면은 스택에 그대로 살아있어
/// 다시 초기화하지 않음) 또는 분석하기(다음 화면으로 진행).
class DocumentScanPreviewPage extends ConsumerWidget {
  const DocumentScanPreviewPage({super.key, required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(easyModeProvider);

    return AppScaffold(
      title: '촬영 결과 확인',
      onBack: () => Navigator.of(context).pop(),
      backLabel: '재촬영',
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.file(File(photo.localPath), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('재촬영'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: '분석하기',
                  size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentScanResultPage(photo: photo),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
