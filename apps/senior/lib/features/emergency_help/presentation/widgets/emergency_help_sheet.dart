import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/emergency_help_di_providers.dart';

/// 긴급 도움 모달 — 119/112/118과 "보호자에게 전화" 모두 실제 다이얼러로
/// 연결한다(`url_launcher`). 보호자 번호는 `get_connected_guardian_phone`
/// RPC로 조회하며, 연결된 보호자가 아직 없으면(정상 상태) 가짜 번호로 연결을
/// 시도하지 않고 정직한 안내만 보여준다.
class EmergencyHelpSheet extends ConsumerWidget {
  const EmergencyHelpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => const EmergencyHelpSheet(),
    );
  }

  Future<void> _call(BuildContext context, WidgetRef ref, String number) async {
    final result = await ref.read(callPhoneUseCaseProvider).call(number);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        break;
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _callGuardian(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(getGuardianPhoneUseCaseProvider).call();
    if (!context.mounted) return;
    switch (result) {
      case Ok(value: final phone?):
        await _call(context, ref, phone);
      case Ok():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.noGuardianConnectedError,
            ),
          ),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.emergencyHelpTitle, style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            _ContactRow(
              label: l10n.callGuardianLabel,
              icon: Icons.phone,
              onTap: () => _callGuardian(context, ref),
            ),
            _ContactRow(
              label: l10n.emergency119Label,
              icon: Icons.local_hospital,
              onTap: () => _call(context, ref, '119'),
            ),
            _ContactRow(
              label: l10n.emergency112Label,
              icon: Icons.local_police,
              onTap: () => _call(context, ref, '112'),
            ),
            _ContactRow(
              label: l10n.emergency118Label,
              icon: Icons.security,
              onTap: () => _call(context, ref, '118'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: label,
          child: Row(
            children: [
              Icon(icon, color: AppColors.error),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
