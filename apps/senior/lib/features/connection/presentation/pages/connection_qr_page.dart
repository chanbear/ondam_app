import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/easy_mode/easy_mode_outline_card.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/connection_token_notifier.dart';

/// 어르신이 보호자에게 보여줄 QR 코드 화면(technical-decisions.md §1-6 v9,
/// ui-screen-spec.md "더보기 — 보호자 연결 QR"). QR을 보여주는 것 자체가
/// 유일한 행동이라 Primary CTA는 없고, 만료됐을 때만 재발급 버튼을 보여준다.
class ConnectionQrPage extends ConsumerWidget {
  const ConnectionQrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenState = ref.watch(connectionTokenProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.guardianConnectTitle,
      onBack: () => Navigator.of(context).pop(),
      body: tokenState.when(
        loading: () => AppLoading(message: l10n.qrGeneratingMessage),
        error: (error, _) => AppError(
          message: l10n.qrGenerateError,
          onRetry: () =>
              ref.read(connectionTokenProvider.notifier).regenerate(),
        ),
        data: (token) =>
            _QrContent(expiresAt: token.expiresAt, data: token.token),
      ),
    );
  }
}

class _QrContent extends ConsumerWidget {
  const _QrContent({required this.expiresAt, required this.data});

  final DateTime expiresAt;
  final String data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpired = DateTime.now().isAfter(expiresAt);
    final easyMode = ref.watch(easyModeProvider);
    final l10n = AppLocalizations.of(context)!;

    final qrImage = Opacity(
      opacity: isExpired ? 0.3 : 1,
      child: QrImageView(data: data, size: 240, version: QrVersions.auto),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.qrShowGuardianPrompt,
            textAlign: TextAlign.center,
            style: easyMode
                ? AppTextStyles.headlineMedium
                : AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          // 2026-08-28 — 쉬운 모드일 때만 `EasyOutlineCard`(굵은 먹색 테두리)로.
          easyMode ? EasyOutlineCard(child: qrImage) : qrImage,
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.qrScanExplanation,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isExpired) ...[
            Text(
              l10n.qrExpiredMessage,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // ui-prototype `senior.qr-generate`와 맞춤 — 만료 여부와 상관없이
          // 항상 재발급(새로고침) 버튼을 보여준다.
          AppButton(
            label: l10n.qrRegenerateButton,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            onPressed: () =>
                ref.read(connectionTokenProvider.notifier).regenerate(),
          ),
        ],
      ),
    );
  }
}
