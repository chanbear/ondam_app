import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../providers/otp_notifier.dart';

/// Step 2 of signup/login: enter the 6-digit OTP code that was texted to
/// [phoneNumber]. On success, the router's `redirect` (app_router.dart)
/// automatically moves the user forward once the Supabase session appears
/// — this page never navigates manually on success.
class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(otpNotifierProvider.notifier)
        .verifyOtp(phoneNumber: widget.phoneNumber, otp: _controller.text);
  }

  Future<void> _resend() async {
    await ref.read(otpNotifierProvider.notifier).requestOtp(widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpNotifierProvider);
    final isLoading = otpState.isLoading;
    final failure = otpState.hasError ? otpState.error as Failure : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('인증번호를 입력해주세요', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${widget.phoneNumber}로 보낸 6자리 인증번호를 입력해주세요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: '인증번호',
                controller: _controller,
                hintText: '000000',
                keyboardType: TextInputType.number,
                errorText: failure?.message,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: '확인',
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: isLoading ? null : _resend,
                child: const Text('인증번호 다시 받기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
