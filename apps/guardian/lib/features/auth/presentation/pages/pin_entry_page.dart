import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../../domain/entities/pin_verify_result.dart';
import '../providers/pin_notifier.dart';
import '../widgets/pin_keypad.dart';

const _pinLength = 4;

/// Everyday app-reentry PIN check (Session ≠ PIN Gate). A wrong PIN or a
/// lockout is a normal domain OUTCOME (`Ok(PinVerifyResult.failure(...))`),
/// not a repository [Failure] — this page keeps the last result locally to
/// display it, since `pinNotifierProvider`'s AsyncValue alone can't tell
/// "wrong PIN" apart from "verified" (both resolve to `AsyncData(null)`).
class PinEntryPage extends ConsumerStatefulWidget {
  const PinEntryPage({super.key});

  @override
  ConsumerState<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends ConsumerState<PinEntryPage> {
  String _entry = '';
  PinVerifyResult? _lastResult;
  Failure? _lastFailure;

  void _onDigit(String digit) {
    if (_entry.length >= _pinLength) return;
    setState(() {
      _entry += digit;
      _lastResult = null;
      _lastFailure = null;
    });
    if (_entry.length == _pinLength) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    final pin = _entry;
    final result = await ref.read(pinNotifierProvider.notifier).verifyPin(pin);
    if (!mounted) return;
    setState(() {
      _entry = '';
      switch (result) {
        case Ok(:final value):
          _lastResult = value;
          _lastFailure = null;
        case Err(:final failure):
          _lastResult = null;
          _lastFailure = failure;
      }
    });
  }

  String? get _guidanceMessage {
    if (_lastFailure != null) return _lastFailure!.message;
    final result = _lastResult;
    if (result == null || result.ok) return null;
    return switch (result.reason!) {
      PinVerifyFailureReason.wrongPin =>
        result.failedAttempts != null
            ? 'PIN이 올바르지 않아요. (${result.failedAttempts}회 실패)'
            : 'PIN이 올바르지 않아요.',
      PinVerifyFailureReason.locked =>
        result.lockedUntil != null
            ? '너무 여러 번 틀렸어요. ${_formatLockedUntil(result.lockedUntil!)}에 다시 시도해주세요.'
            : '너무 여러 번 틀려서 잠시 잠겼어요. 잠시 후 다시 시도해주세요.',
      PinVerifyFailureReason.pinNotSet => 'PIN이 설정되어 있지 않아요.',
      PinVerifyFailureReason.invalidFormat => 'PIN은 4자리 숫자예요.',
      PinVerifyFailureReason.unknown => '확인 중 문제가 발생했어요. 다시 시도해주세요.',
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
    final pinState = ref.watch(pinNotifierProvider);
    final isLoading = pinState.isLoading;
    final guidance = _guidanceMessage;
    final isLocked = _lastResult?.reason == PinVerifyFailureReason.locked;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PIN을 입력해주세요',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (guidance != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  guidance,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (isLoading)
                const AppLoading()
              else
                PinKeypad(
                  pinLength: _pinLength,
                  enteredLength: _entry.length,
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  enabled: !isLocked,
                ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.push(AuthRoutes.pinForgot),
                child: const Text('PIN을 잊으셨나요?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
