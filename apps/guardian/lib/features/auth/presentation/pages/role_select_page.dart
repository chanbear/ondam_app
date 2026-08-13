import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../providers/role_notifier.dart';

/// Onboarding role choice — role is never inferred from which app you
/// installed (technical-decisions.md §1-3-A "Role 관리"), so even in the
/// Guardian app the user explicitly picks. If the phone number already
/// holds the opposite role (same-phone dual role, DECIDED B안), a
/// non-blocking informational note is shown — it never prevents proceeding.
class RoleSelectPage extends ConsumerWidget {
  const RoleSelectPage({super.key});

  Future<void> _select(WidgetRef ref, UserRole role) {
    return ref.read(roleNotifierProvider.notifier).addRole(role);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(roleNotifierProvider);
    final existingRoles = rolesAsync.value ?? const <UserRole>[];
    final hasOppositeRole = existingRoles.isNotEmpty;
    final isLoading = rolesAsync.isLoading && rolesAsync.hasValue;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('어떤 분으로 이용하실까요?', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '이용 목적에 맞게 화면을 준비해드릴게요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (hasOppositeRole) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '이 번호는 이미 다른 역할로 등록되어 있어요. 계속 진행하면 이 역할도 함께 등록돼요.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: '저는 가족(보호자)이에요',
                isLoading: isLoading,
                onPressed: isLoading
                    ? null
                    : () => _select(ref, UserRole.guardian),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: '저는 어르신이에요',
                isLoading: isLoading,
                onPressed: isLoading
                    ? null
                    : () => _select(ref, UserRole.elder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
