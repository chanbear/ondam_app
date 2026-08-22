import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/sign_up_notifier.dart';

/// Signup/login entry point: name + phone number, no OTP step (see
/// technical-decisions.md §1-3-A "OTP 제거"). On success the router's
/// `redirect` (app_router.dart) automatically moves the user forward once
/// the Supabase session appears — this page never navigates manually.
class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(signUpNotifierProvider.notifier)
        .signUp(
          name: _nameController.text,
          rawPhoneNumber: _phoneController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signUpState = ref.watch(signUpNotifierProvider);
    final isLoading = signUpState.isLoading;
    final failure = signUpState.hasError ? signUpState.error as Failure : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.phoneStartTitle, style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.phoneStartSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(label: l10n.nameLabel, controller: _nameController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.phoneNumberLabel,
                controller: _phoneController,
                hintText: l10n.phoneNumberHint,
                keyboardType: TextInputType.phone,
                errorText: failure?.message,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.startButton,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
