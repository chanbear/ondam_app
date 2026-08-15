import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../auth/presentation/providers/auth_di_providers.dart';
import '../../../auth/presentation/providers/pin_notifier.dart';

/// 설정 — 계정(로그아웃/탈퇴), 위험 알림 설정. 위험 알림 on/off는
/// `notification` feature 도메인이 없어 아직 실제 값을 저장하지 못한다 —
/// 이번 라운드에서는 노출하지 않는다.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '정말 탈퇴하시겠어요?',
      message: '탈퇴하면 계정과 함께 저장된 모든 정보가 즉시 삭제되고 되돌릴 수 없어요.',
      confirmLabel: '탈퇴하기',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(pinNotifierProvider.notifier).deleteAccount();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: '설정',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: '계정'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('로그아웃'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(signOutUseCaseProvider).call(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '회원 탈퇴',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}
