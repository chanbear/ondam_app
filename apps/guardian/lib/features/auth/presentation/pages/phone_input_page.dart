import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../providers/otp_notifier.dart';

/// Step 1 of signup/login: enter phone number, request OTP.
class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(otpNotifierProvider.notifier);
    final result = await notifier.requestOtp(_controller.text);
    if (!mounted) return;
    if (result case Ok(:final value)) {
      context.push(AuthRoutes.otpVerify, extra: value);
    }
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
              Text('휴대폰 번호로 시작하기', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '인증번호를 보내드릴게요. 본인 명의 휴대폰 번호를 입력해주세요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: '휴대폰 번호',
                controller: _controller,
                hintText: '010-0000-0000',
                keyboardType: TextInputType.phone,
                errorText: failure?.message,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: '인증번호 받기',
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
