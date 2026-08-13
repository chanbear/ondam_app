import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../auth/presentation/providers/auth_di_providers.dart';
import '../../../auth/presentation/providers/pin_notifier.dart';
import '../../../onboarding/presentation/widgets/accessibility_settings_form.dart';

/// 설정 — 접근성, 쉬운 모드, 계정(로그아웃/탈퇴). `보호자 알림 설정`과
/// `개인정보 공개 범위 안내`는 각각 `notification`/공지 문구 확정 이후로
/// 미루고 이번에는 노출하지 않는다(있지도 않은 토글을 보여주지 않기 위함).
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
    final easyMode = ref.watch(easyModeProvider);

    return AppScaffold(
      title: '설정',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: '쉬운 모드'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('쉬운 모드'),
            subtitle: const Text('큰 버튼과 단순한 화면으로 바꿔드려요'),
            value: easyMode,
            onChanged: (_) => ref.read(easyModeProvider.notifier).toggle(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const AccessibilitySettingsForm(),
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: '계정'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('로그아웃'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(signOutUseCaseProvider).call(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('회원 탈퇴', style: TextStyle(color: AppColors.error)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}
