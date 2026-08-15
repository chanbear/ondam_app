import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../providers/emergency_help_di_providers.dart';

/// 긴급 도움 모달 — 119/112/118은 실제 다이얼러로 연결한다(`url_launcher`).
/// "보호자에게 전화"는 보호자 전화번호를 조회할 데이터 소스가 아직 없어
/// (guardian_links는 guardian_id만 가짐, 전화번호를 노출하는 profile 테이블
/// 부재) 실제 연결 대신 정직한 안내로 남긴다 — 없는 번호로 가짜 연결을
/// 시도하지 않는다.
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

  void _showGuardianNumberUnavailable(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('보호자 전화번호를 아직 알 수 없어요.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('도움이 필요하신가요?', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            _ContactRow(
              label: '보호자에게 전화',
              icon: Icons.phone,
              onTap: () => _showGuardianNumberUnavailable(context),
            ),
            _ContactRow(
              label: '119 (응급구조)',
              icon: Icons.local_hospital,
              onTap: () => _call(context, ref, '119'),
            ),
            _ContactRow(
              label: '112 (경찰)',
              icon: Icons.local_police,
              onTap: () => _call(context, ref, '112'),
            ),
            _ContactRow(
              label: '118 (사이버 신고)',
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
