import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../providers/pin_notifier.dart';
import '../widgets/pin_keypad.dart';

const _pinLength = 4;

/// First-time PIN setup — enter 4 digits, then re-enter to confirm before
/// calling `set-pin`. On success, the router's `redirect` moves the user
/// forward automatically (role selection or home).
class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  String _firstEntry = '';
  String _currentEntry = '';
  bool _confirming = false;
  String? _mismatchMessage;

  void _onDigit(String digit) {
    if (_currentEntry.length >= _pinLength) return;
    setState(() {
      _mismatchMessage = null;
      _currentEntry += digit;
    });

    if (_currentEntry.length == _pinLength) {
      if (!_confirming) {
        final entered = _currentEntry;
        setState(() {
          _firstEntry = entered;
          _confirming = true;
          _currentEntry = '';
        });
      } else {
        if (_currentEntry == _firstEntry) {
          ref.read(pinNotifierProvider.notifier).setPin(_currentEntry);
        } else {
          setState(() {
            _mismatchMessage = 'PIN이 일치하지 않아요. 처음부터 다시 입력해주세요.';
            _firstEntry = '';
            _confirming = false;
            _currentEntry = '';
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_currentEntry.isEmpty) return;
    setState(() {
      _currentEntry = _currentEntry.substring(0, _currentEntry.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinNotifierProvider);
    final isLoading = pinState.isLoading;
    final failure = pinState.hasError ? pinState.error as Failure : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _confirming ? '한 번 더 입력해주세요' : '사용하실 PIN 4자리를 정해주세요',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '다음부터 앱을 열 때 이 PIN으로 확인해요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_mismatchMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _mismatchMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              if (failure != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  failure.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (isLoading)
                const AppLoading()
              else
                PinKeypad(
                  pinLength: _pinLength,
                  enteredLength: _currentEntry.length,
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
