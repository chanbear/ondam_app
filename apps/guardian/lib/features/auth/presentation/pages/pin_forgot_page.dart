import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../../../../core/auth/supabase_client_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/pin_notifier.dart';
import '../providers/sign_up_notifier.dart';
import '../widgets/pin_keypad.dart';

const _pinLength = 4;

/// PIN-forgot flow: re-authenticate (a fresh sign-in via the same
/// name+phone `signup-with-phone` call as the login screen — no OTP, see
/// technical-decisions.md §1-3-A "OTP 제거"; this refreshes `last_sign_in_at`
/// so `reset-pin`'s freshness check still passes), then set a new PIN. Two
/// local UI steps within one page/route (flutter.md: local step sequencing
/// is legitimate `StatefulWidget` state, not global business state).
class PinForgotPage extends ConsumerStatefulWidget {
  const PinForgotPage({super.key});

  @override
  ConsumerState<PinForgotPage> createState() => _PinForgotPageState();
}

enum _Step { reauthenticating, newPin }

class _PinForgotPageState extends ConsumerState<PinForgotPage> {
  _Step _step = _Step.reauthenticating;
  String _newPinEntry = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reauthenticate());
  }

  Future<void> _reauthenticate() async {
    final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
    final rawPhone = currentUser?.phone;
    if (rawPhone == null || rawPhone.isEmpty) return;
    final phoneNumber = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';
    final name = currentUser?.userMetadata?['name'] as String? ?? phoneNumber;

    final result = await ref
        .read(signUpNotifierProvider.notifier)
        .signUp(name: name, rawPhoneNumber: phoneNumber);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pinForgotTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: switch (_step) {
            _Step.reauthenticating => _ReauthenticatingStep(
              onRetry: _reauthenticate,
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

class _ReauthenticatingStep extends ConsumerWidget {
  const _ReauthenticatingStep({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signUpState = ref.watch(signUpNotifierProvider);
    final failure = signUpState.hasError ? signUpState.error as Failure : null;

    if (failure == null) {
      return const Center(child: AppLoading());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pinForgotReauthFailedTitle,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          failure.message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: l10n.retryButtonLabel, onPressed: onRetry),
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
    final l10n = AppLocalizations.of(context)!;
    final pinState = ref.watch(pinNotifierProvider);
    final isLoading = pinState.isLoading;
    final failure = pinState.hasError ? pinState.error as Failure : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.pinForgotNewPinTitle,
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
