import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/failure_l10n.dart';
import '../../../../core/voice_guide/voice_guide_scaffold.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/benefit_service.dart';
import '../providers/benefit_service_detail_provider.dart';

/// 혜택 정보 상세 — `welfare_center_list_page.dart`의 전화 연결 패턴을
/// 그대로 재사용한다.
class BenefitServiceDetailPage extends ConsumerWidget {
  const BenefitServiceDetailPage({
    super.key,
    required this.id,
    required this.source,
  });

  final String id;
  final BenefitServiceSource source;

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final launched = await launchUrl(Uri.parse(url));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.linkLaunchError)));
    }
  }

  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    final l10n = AppLocalizations.of(context)!;
    final launched = await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.phoneLaunchError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(
      benefitServiceDetailProvider((id: id, source: source)),
    );

    return VoiceGuideScaffold(
      title: l10n.benefitServiceDetailTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: detailAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) {
          final message = error is Failure
              ? localizeFailureMessage(context, error.message)
              : l10n.benefitServiceDetailLoadError;
          return AppError(
            message: message,
            onRetry: () => ref.invalidate(
              benefitServiceDetailProvider((id: id, source: source)),
            ),
          );
        },
        data: (detail) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            Text(detail.summary, style: AppTextStyles.bodyLarge),
            if (detail.supportTarget != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppInfoRow(
                label: l10n.supportTargetLabel,
                value: detail.supportTarget,
              ),
            ],
            if (detail.applyMethod != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppInfoRow(
                label: l10n.applyMethodLabel,
                value: detail.applyMethod,
              ),
            ],
            if (detail.contact != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.contactCallButton,
                size: AppButtonSize.large,
                onPressed: () => _callPhone(context, detail.contact!),
              ),
            ],
            if (detail.externalUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.viewDetailButton,
                size: AppButtonSize.large,
                onPressed: () => _openExternalUrl(context, detail.externalUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
