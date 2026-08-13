import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/connection_token_notifier.dart';

/// 어르신이 보호자에게 보여줄 QR 코드 화면(technical-decisions.md §1-6 v9,
/// ui-screen-spec.md "더보기 — 보호자 연결 QR"). QR을 보여주는 것 자체가
/// 유일한 행동이라 Primary CTA는 없고, 만료됐을 때만 재발급 버튼을 보여준다.
class ConnectionQrPage extends ConsumerWidget {
  const ConnectionQrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenState = ref.watch(connectionTokenProvider);

    return AppScaffold(
      title: '보호자 연결',
      onBack: () => Navigator.of(context).pop(),
      body: tokenState.when(
        loading: () => const AppLoading(message: 'QR 코드를 만들고 있어요'),
        error: (error, _) => AppError(
          message: 'QR 코드를 만들지 못했어요. 다시 시도해주세요.',
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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '보호자에게 이 QR을 보여주세요',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '보호자가 이 QR을 스캔하면 연결 요청이 도착합니다.',
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
            const Text('QR이 만료되었어요.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'QR 다시 만들기',
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
