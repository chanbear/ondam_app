import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// 개인정보 보관 안내 — 이 저장소에서 실제로 확정·구현된 정책만 안내한다
/// (technical-decisions.md §1-3-A/§1-8/§2-3). 아직 확정되지 않은 항목(분석
/// 결과 원문 보관 기간, §5 OPEN QUESTIONS 5번)은 있는 그대로 "미확정"으로
/// 안내한다 — 확정된 것처럼 지어내지 않는다.
class PrivacyInfoPage extends StatelessWidget {
  const PrivacyInfoPage({super.key});

  List<(IconData, String, String)> _items(AppLocalizations l10n) => [
    (Icons.pin_outlined, l10n.privacyPinTitle, l10n.privacyPinBody),
    (
      Icons.photo_camera_back_outlined,
      l10n.privacyPhotoTitle,
      l10n.privacyPhotoBody,
    ),
    (
      Icons.family_restroom_outlined,
      l10n.privacySharedInfoTitle,
      l10n.privacySharedInfoBody,
    ),
    (
      Icons.delete_outline,
      l10n.deleteAccount,
      l10n.deleteAccountConfirmMessage,
    ),
    (Icons.help_outline, l10n.privacyRetentionTitle, l10n.privacyRetentionBody),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.privacyInfoTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, title, body) in _items(l10n)) ...[
            _PrivacyItem(icon: icon, title: title, body: body),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
