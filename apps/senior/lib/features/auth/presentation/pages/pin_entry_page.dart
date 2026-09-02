import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../../../../core/l10n/failure_l10n.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

  String? _guidanceMessage(AppLocalizations l10n) {
    if (_lastFailure != null) {
      return localizeFailureMessageWith(l10n, _lastFailure!.message);
    }
    final result = _lastResult;
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
    final pinState = ref.watch(pinNotifierProvider);
    final isLoading = pinState.isLoading;
    final l10n = AppLocalizations.of(context)!;
    final guidance = _guidanceMessage(l10n);
    final isLocked = _lastResult?.reason == PinVerifyFailureReason.locked;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // 시스템 폰트 확대(textScaler)로 고정 Column 높이를 넘길 수 있어
          // phone_input_page와 동일하게 LayoutBuilder + SingleChildScrollView로
          // 감싼다 (ui-design.md Responsive UI).
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.pinEntryPrompt,
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
                      child: Text(l10n.pinForgotLink),
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
