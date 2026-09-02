import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/auth/supabase_client_provider.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/l10n/failure_l10n.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/pin_verify_result.dart';
import '../../domain/entities/social_auth_provider.dart';
import '../providers/has_pin_provider.dart';
import '../providers/login_notifier.dart';

/// ONDAM 2.0V 로그인 화면(요구사항 2/3) — 휴대폰 번호와 비밀번호(PIN)를
/// 하나의 화면에서 입력받는다. 별도의 "PIN 입력창"으로 넘어가는 느낌 없이
/// [LoginNotifier]가 가입/로그인/PIN 최초 설정/PIN 확인/역할 자동 결정을
/// 순서대로 처리하고 나면, 라우터의 `redirect`가 자동으로 다음 화면으로
/// 넘겨준다(이 페이지는 직접 내비게이션하지 않는다).
class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  PinVerifyResult? _lastPinResult;

  /// [_maybeAutoCompleteSocialLogin]이 이미 트리거됐는지 — build()가 여러
  /// 번 다시 불려도(ref.watch로 인한 rebuild) 한 번만 호출되게 막는다.
  bool _socialLoginAutoCompleteTriggered = false;

  /// 소셜 로그인 또는 게스트 세션이 감지되면 PIN 없이 곧장 역할 부여를
  /// 자동으로 진행한다(사용자 요청: 이 두 경우 모두 PIN 입력을 생략) —
  /// 사용자가 버튼을 누를 필요가 없다.
  void _maybeAutoCompleteSocialLogin(bool skipsPinGate) {
    if (!skipsPinGate || _socialLoginAutoCompleteTriggered) return;
    _socialLoginAutoCompleteTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginNotifierProvider.notifier).completeSocialLoginSession();
    });
  }

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

  /// OAuth(구글)로 이미 세션이 있는 상태(휴대폰 번호가 없는 계정)에서
  /// PIN만 입력받아 제출한다 — [_submit]과 달리 signUp(휴대폰) 호출이 없다.
  Future<void> _submitPinOnly() async {
    setState(() => _lastPinResult = null);
    final result = await ref
        .read(loginNotifierProvider.notifier)
        .submitPinForExistingSession(_pinController.text);
    if (!mounted) return;
    if (result case Ok(:final value) when !value.ok) {
      setState(() => _lastPinResult = value);
    }
  }

  Future<void> _startOAuth(SocialAuthProvider provider) async {
    await ref.read(loginNotifierProvider.notifier).signInWithOAuth(provider);
  }

  Future<void> _startGuest() async {
    await ref.read(loginNotifierProvider.notifier).signInAsGuest();
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
    final currentUser = ref
        .read(supabaseClientProvider)
        .auth
        .currentSession
        ?.user;
    final hasSession = currentUser != null;
    // signup-with-phone으로 만든 세션은 항상 phone이 채워져 있다 — OAuth로
    // 만들어진 세션(구글)이나 게스트(익명) 세션은 휴대폰 번호가 없으므로
    // 이 값으로 구분한다. 이 사용자들은 재입력할 휴대폰 번호 자체가 없으니
    // PIN도 아예 생략하고(2026-08-31 — 이전에는 게스트만 제외돼 PIN 설정
    // 화면을 보는 버그였다) 곧장 역할 부여로 넘어간다. `app_router.dart`의
    // `skipsPinGate` 판별과 같은 신호.
    final skipsPinGate =
        hasSession && (currentUser.phone == null || currentUser.phone!.isEmpty);
    _maybeAutoCompleteSocialLogin(skipsPinGate);
    if (skipsPinGate) {
      // 역할 부여(completeSocialLoginSession)가 실패하면(네트워크 오류 등)
      // skipsPinGate는 계속 true로 남는다 — 여기서 실패를 구분하지
      // 않으면 사용자가 원인도 재시도 방법도 모른 채 로딩 화면만 영원히
      // 보게 된다(2026-08-30 실기기에서 재현된 버그).
      if (failure != null) {
        return Scaffold(
          body: AppError(
            message: localizeFailureMessage(context, failure.message),
            onRetry: () => ref
                .read(loginNotifierProvider.notifier)
                .completeSocialLoginSession(),
          ),
        );
      }
      // 라우터가 역할 자동 부여를 감지하는 즉시 이 화면을 벗어난다 —
      // `SessionLoadingPage`와 같은 중립 로딩 화면.
      return const Scaffold(body: AppLoading());
    }
    final hasPin = ref.watch(hasPinProvider).value;
    final isLocked = _lastPinResult?.reason == PinVerifyFailureReason.locked;
    // Easy Mode — ui-prototype `easy.auth-login`과 같은 톤(큰 글씨)이지만
    // 입력 필드는 기존 AppTextField 그대로 재사용한다. 굵은 테두리 카드는
    // 2026-08-29 ui-prototype에서 삭제된 시각 요소라 여기서도 쓰지 않는다.
    final easyMode = ref.watch(easyModeProvider);
    final fields = skipsPinGate
        ? AppTextField(
            label: l10n.pinLabel,
            controller: _pinController,
            hintText: l10n.pinHint,
            obscureText: true,
            keyboardType: TextInputType.number,
            errorText: _pinGuidance(l10n),
          )
        : Column(
            children: [
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
            ],
          );
    final title = skipsPinGate
        ? (hasPin == true ? l10n.oauthPinEntryTitle : l10n.oauthPinSetupTitle)
        : l10n.phoneStartTitle;
    final subtitle = skipsPinGate
        ? (hasPin == true
              ? l10n.oauthPinEntrySubtitle
              : l10n.oauthPinSetupSubtitle)
        : l10n.phoneStartSubtitle;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // Easy Mode의 큰 글씨 + 굵은 테두리 카드는 접근성 글자 배율(1.4x)에서
          // 고정 Column 높이를 넘길 수 있다 — LayoutBuilder + ConstrainedBox로
          // 내용이 맞으면 기존처럼 가운데 정렬, 넘치면 스크롤되게 한다.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: easyMode
                          ? AppTextStyles.displayLarge
                          : AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      style:
                          (easyMode
                                  ? AppTextStyles.titleMedium
                                  : AppTextStyles.bodyMedium)
                              .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    fields,
                    if (failure != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        localizeFailureMessage(context, failure.message),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.startButton,
                      size: easyMode
                          ? AppButtonSize.large
                          : AppButtonSize.standard,
                      isLoading: isLoading,
                      onPressed: (isLoading || isLocked)
                          ? null
                          : (skipsPinGate ? _submitPinOnly : _submit),
                    ),
                    if (!skipsPinGate) ...[
                      const SizedBox(height: AppSpacing.md),
                      _OrDivider(label: l10n.socialLoginDivider),
                      const SizedBox(height: AppSpacing.sm),
                      _SocialLoginButton(
                        label: l10n.googleLoginButton,
                        backgroundColor: AppColors.surface,
                        borderColor: AppColors.border,
                        textColor: AppColors.textPrimary,
                        badge: const _GoogleBadge(),
                        onPressed: isLoading
                            ? null
                            : () => _startOAuth(SocialAuthProvider.google),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l10n.guestSignInButton,
                        variant: AppButtonVariant.text,
                        onPressed: isLoading ? null : _startGuest,
                      ),
                    ],
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
          ),
        ),
      ),
    );
  }
}

/// ui-prototype `.or-div` — 좌우 구분선 사이에 문구를 넣는 구분자.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(color: AppColors.divider));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// ui-prototype `.social-btn` — full-width pill 소셜 로그인 버튼.
class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.badge,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Widget badge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, AppTouch.easy),
        backgroundColor: backgroundColor,
        side: BorderSide(color: borderColor),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          badge,
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 카카오/네이버처럼 로고 이미지 대신 짧은 텍스트 배지를 쓰는 브랜드용.
class _TextBadge extends StatelessWidget {
  const _TextBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: text.length > 1 ? 7 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// 구글 배지 — 정식 4색 로고 대신 브랜드 블루 "G" 텍스트 배지로 단순화
/// (플레이스홀더 버튼에 SVG 로고를 픽셀 단위로 재현할 필요는 없다).
class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return const _TextBadge(
      text: 'G',
      background: Color(0xFF4285F4),
      foreground: AppColors.surface,
    );
  }
}
