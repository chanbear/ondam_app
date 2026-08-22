import 'auth_routes.dart';

/// Pure decision function for the auth `redirect` state machine — kept
/// separate from `app_router.dart`'s provider-reading glue so the 3-state
/// model (technical-decisions.md §1-3-A) is unit-testable without faking
/// Supabase/Riverpod. Returns the path to redirect to, or `null` to allow
/// [location] as-is.
///
/// ONDAM 2.0V(요구사항 2/3/4) — 휴대폰 번호+비밀번호(PIN) 입력, PIN 최초
/// 설정, PIN 확인을 모두 [AuthRoutes.phoneInput] 하나의 화면에서 처리한다
/// (LoginNotifier가 순서대로 호출). 이전에는 이 세 가지가 각각
/// `/auth/pin/setup`/`/auth/pin/entry`로 갈라지는 별도 화면이었다. 마찬가지로
/// 역할은 Senior 앱에서 자동으로 결정되므로(LoginNotifier) `roleSelect`
/// 화면으로도 더 이상 보내지 않는다 — 역할이 비어있는 짧은 순간에는
/// [AuthRoutes.sessionLoading]에서 대기하다가, 자동 등록이 끝나면 이
/// redirect가 다시 평가되어 홈으로 넘어간다.
String? decideAuthRedirect({
  required bool hasSession,
  required bool? hasPin,
  required bool pinVerified,
  required List<Object>? roles,
  required String location,
}) {
  final onLogin = location == AuthRoutes.phoneInput;
  final onPinForgot = location == AuthRoutes.pinForgot;

  if (!hasSession) {
    if (onLogin) return null;
    return AuthRoutes.phoneInput;
  }

  // PIN-forgot always needs a fresh re-signin mid-flow even though a
  // session already exists — let it run to completion; it exits via an
  // explicit context.go(home) on success, not via this redirect.
  if (onPinForgot) return null;

  if (hasPin == null) {
    return AuthRoutes.sessionLoading;
  }

  if (!hasPin || !pinVerified) {
    if (onLogin) return null;
    return AuthRoutes.phoneInput;
  }

  if (roles == null) {
    return AuthRoutes.sessionLoading;
  }

  if (roles.isEmpty) {
    return AuthRoutes.sessionLoading;
  }

  if (onLogin) return AuthRoutes.home;
  return null;
}
