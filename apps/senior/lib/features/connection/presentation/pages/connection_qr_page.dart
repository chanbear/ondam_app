import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.qrShowGuardianPrompt,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.qrScanExplanation,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Opacity(
            opacity: isExpired ? 0.3 : 1,
            child: QrImageView(data: data, size: 240, version: QrVersions.auto),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isExpired) ...[
            Text(l10n.qrExpiredMessage, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.qrRegenerateButton,
              size: AppButtonSize.large,
              onPressed: () =>
                  ref.read(connectionTokenProvider.notifier).regenerate(),
            ),
          ],
        ],
      ),
    );
  }
}
