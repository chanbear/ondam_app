import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../../../../core/auth/supabase_client_provider.dart';
import '../providers/otp_notifier.dart';
import '../providers/pin_notifier.dart';
import '../widgets/pin_keypad.dart';

const _pinLength = 4;

/// PIN-forgot flow: re-authenticate via a fresh OTP (never decrypts/
/// recovers the old PIN — bcrypt is one-way), then set a new PIN. Two
/// local UI steps within one page/route (flutter.md: local step sequencing
/// is legitimate `StatefulWidget` state, not global business state).
class PinForgotPage extends ConsumerStatefulWidget {
  const PinForgotPage({super.key});

  @override
  ConsumerState<PinForgotPage> createState() => _PinForgotPageState();
}

enum _Step { requestOtp, enterOtp, newPin }

class _PinForgotPageState extends ConsumerState<PinForgotPage> {
  _Step _step = _Step.requestOtp;
  final _otpController = TextEditingController();
  String _newPinEntry = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? get _currentPhoneNumber =>
      ref.read(supabaseClientProvider).auth.currentUser?.phone;

  Future<void> _sendOtp() async {
    final phoneNumber = _currentPhoneNumber;
    if (phoneNumber == null) return;
    final result = await ref
        .read(otpNotifierProvider.notifier)
        .requestOtp(phoneNumber);
    if (!mounted) return;
    if (result is Ok<String>) {
      setState(() => _step = _Step.enterOtp);
    }
  }

  Future<void> _verifyOtp() async {
    final phoneNumber = _currentPhoneNumber;
    if (phoneNumber == null) return;
    final result = await ref
        .read(otpNotifierProvider.notifier)
        .verifyOtp(phoneNumber: phoneNumber, otp: _otpController.text);
    if (!mounted) return;
    if (result is Ok<void>) {
      setState(() => _step = _Step.newPin);
    }
  }

  Future<void> _onNewPinDigit(String digit) async {
    if (_newPinEntry.length >= _pinLength) return;
    setState(() => _newPinEntry += digit);
    if (_newPinEntry.length == _pinLength) {
      final pin = _newPinEntry;
      final result = await ref.read(pinNotifierProvider.notifier).resetPin(pin);
      if (!mounted) return;
      if (result is Ok<void>) {
        context.go(AuthRoutes.home);
      } else {
        setState(() => _newPinEntry = '');
      }
    }
  }

  void _onNewPinBackspace() {
    if (_newPinEntry.isEmpty) return;
    setState(
      () => _newPinEntry = _newPinEntry.substring(0, _newPinEntry.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PIN 재설정')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: switch (_step) {
            _Step.requestOtp => _RequestOtpStep(onSend: _sendOtp),
            _Step.enterOtp => _EnterOtpStep(
              controller: _otpController,
              onVerify: _verifyOtp,
              onResend: _sendOtp,
            ),
            _Step.newPin => _NewPinStep(
              enteredLength: _newPinEntry.length,
              onDigit: _onNewPinDigit,
              onBackspace: _onNewPinBackspace,
            ),
          },
        ),
      ),
    );
  }
}

class _RequestOtpStep extends ConsumerWidget {
  const _RequestOtpStep({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpState = ref.watch(otpNotifierProvider);
    final isLoading = otpState.isLoading;
    final failure = otpState.hasError ? otpState.error as Failure : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('본인 확인이 필요해요', style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '가입하신 휴대폰 번호로 인증번호를 보내드릴게요.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            failure.message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: '인증번호 받기',
          isLoading: isLoading,
          onPressed: isLoading ? null : onSend,
        ),
      ],
    );
  }
}

class _EnterOtpStep extends ConsumerWidget {
  const _EnterOtpStep({
    required this.controller,
    required this.onVerify,
    required this.onResend,
  });

  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpState = ref.watch(otpNotifierProvider);
    final isLoading = otpState.isLoading;
    final failure = otpState.hasError ? otpState.error as Failure : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('인증번호를 입력해주세요', style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: '인증번호',
          controller: controller,
          hintText: '000000',
          keyboardType: TextInputType.number,
          errorText: failure?.message,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: '확인',
          isLoading: isLoading,
          onPressed: isLoading ? null : onVerify,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: isLoading ? null : onResend,
          child: const Text('인증번호 다시 받기'),
        ),
      ],
    );
  }
}

class _NewPinStep extends ConsumerWidget {
  const _NewPinStep({
    required this.enteredLength,
    required this.onDigit,
    required this.onBackspace,
  });

  final int enteredLength;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinNotifierProvider);
    final isLoading = pinState.isLoading;
    final failure = pinState.hasError ? pinState.error as Failure : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '새로운 PIN 4자리를 정해주세요',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            failure.message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (isLoading)
          const AppLoading()
        else
          PinKeypad(
            pinLength: _pinLength,
            enteredLength: enteredLength,
            onDigit: onDigit,
            onBackspace: onBackspace,
          ),
      ],
    );
  }
}
