import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 긴급 도움 모달 — 보호자/119/112/118 연결. 실제 전화 연결(다이얼러 실행)은
/// `url_launcher` 패키지 도입이 필요해 이번 Phase에서는 구현하지 않는다(불필요한
/// package 추가를 피하기 위해 미리 넣지 않음 — 최종 보고서 "미구현 사항" 참고).
/// 지금은 UI/정보 구조만 확정한다.
class EmergencyHelpSheet extends StatelessWidget {
  const EmergencyHelpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => const EmergencyHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('도움이 필요하신가요?', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            _ContactRow(label: '보호자에게 전화', icon: Icons.phone),
            _ContactRow(label: '119 (응급구조)', icon: Icons.local_hospital),
            _ContactRow(label: '112 (경찰)', icon: Icons.local_police),
            _ContactRow(label: '118 (사이버 신고)', icon: Icons.security),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('전화 연결 기능은 준비 중이에요.')));
        },
        child: Row(
          children: [
            Icon(icon, color: AppColors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
