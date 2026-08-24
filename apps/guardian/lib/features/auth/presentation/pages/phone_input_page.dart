import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/auth/supabase_client_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/pin_verify_result.dart';
import '../providers/login_notifier.dart';

/// Guardian UI Application Round 1 §5 — Senior와 동일하게 휴대폰 번호와
/// 비밀번호(PIN)를 하나의 화면에서 입력받는다. 별도의 "PIN 입력창"으로
/// 넘어가는 느낌 없이 [LoginNotifier]가 가입/로그인/PIN 최초 설정/PIN
/// 확인/역할 자동 결정을 순서대로 처리하고 나면, 라우터의 `redirect`가
/// 자동으로 다음 화면으로 넘겨준다(이 페이지는 직접 내비게이션하지 않는다).
class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  PinVerifyResult? _lastPinResult;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _lastPinResult = null);
    final result = await ref
        .read(loginNotifierProvider.notifier)
        .submit(
          rawPhoneNumber: _phoneController.text,
          pin: _pinController.text,
        );
    if (!mounted) return;
    if (result case Ok(:final value) when !value.ok) {
      setState(() => _lastPinResult = value);
    }
  }

  String? _pinGuidance(AppLocalizations l10n) {
    final result = _lastPinResult;
    if (result == null || result.ok) return null;
    return switch (result.reason!) {
      PinVerifyFailureReason.wrongPin =>
        result.failedAttempts != null
            ? l10n.pinWrongWithCount(result.failedAttempts!)
            : l10n.pinWrong,
      PinVerifyFailureReason.locked =>
        result.lockedUntil != null
            ? l10n.pinLockedWithTime(_formatLockedUntil(result.lockedUntil!))
            : l10n.pinLockedNoTime,
      PinVerifyFailureReason.pinNotSet => l10n.pinNotSet,
      PinVerifyFailureReason.invalidFormat => l10n.pinInvalidFormat,
      PinVerifyFailureReason.unknown => l10n.pinUnknownError,
    };
  }

  String _formatLockedUntil(DateTime lockedUntil) {
    final local = lockedUntil.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.watch(loginNotifierProvider);
    final isLoading = loginState.isLoading;
    final failure = loginState.hasError ? loginState.error as Failure : null;
    // 세션 존재 여부에 따라 "비밀번호를 잊으셨나요?" 링크를 보여줄지
    // 결정한다 — PinForgotPage는 이미 로그인된 계정의 재인증 흐름이라
    // 세션이 없는 상태에서는 의미가 없다.
    ref.watch(authStateChangesProvider);
    final hasSession =
        ref.read(supabaseClientProvider).auth.currentSession != null;
    final isLocked = _lastPinResult?.reason == PinVerifyFailureReason.locked;

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
              AppTextField(
                label: l10n.phoneNumberLabel,
                controller: _phoneController,
                hintText: l10n.phoneNumberHint,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.pinLabel,
                controller: _pinController,
                hintText: l10n.pinHint,
                obscureText: true,
                keyboardType: TextInputType.number,
                errorText: _pinGuidance(l10n),
              ),
              if (failure != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  failure.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.startButton,
                isLoading: isLoading,
                onPressed: (isLoading || isLocked) ? null : _submit,
              ),
              if (hasSession) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.push(AuthRoutes.pinForgot),
                  child: Text(l10n.forgotPinLink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
