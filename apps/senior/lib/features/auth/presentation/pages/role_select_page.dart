import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/role_notifier.dart';
import '../widgets/app_mark.dart';

/// Onboarding role choice — role is never inferred from which app you
/// installed (technical-decisions.md §1-3-A "Role 관리"), so even in the
/// Senior app the user explicitly picks. If the phone number already holds
/// the opposite role (same-phone dual role, DECIDED B안), a non-blocking
/// informational note is shown — it never prevents proceeding.
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // phone_input_page와 동일한 첫인상 화면 구조 — textScaler 확대에
          // 대비해 스크롤 가능하게 감싼다 (ui-design.md Responsive UI).
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppMark(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.roleSelectTitle,
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.roleSelectSubtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hasOppositeRole) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        child: Text(
                          l10n.roleAlreadyRegisteredNotice,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: l10n.roleElderButton,
                      isLoading: isLoading,
                      onPressed: isLoading
                          ? null
                          : () => _select(ref, UserRole.elder),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: l10n.roleGuardianButton,
                      isLoading: isLoading,
                      onPressed: isLoading
                          ? null
                          : () => _select(ref, UserRole.guardian),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
