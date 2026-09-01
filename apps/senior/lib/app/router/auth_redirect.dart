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
  required bool skipsPinGate,
  required List<Object>? roles,
  required String location,
}) {
  final onLogin = location == AuthRoutes.phoneInput;
  final onSplash = location == AuthRoutes.splash;
  final onPinForgot = location == AuthRoutes.pinForgot;

  if (!hasSession) {
    // 스플래시(`AuthRoutes.splash`)는 앱의 `initialLocation`으로만 쓰인다 —
    // 세션이 없을 때 다른 모든 경로는 그대로 로그인 화면으로 보내되, 이
    // 최초 진입 화면만은 예외로 머무르게 한다. 로그아웃 후 재진입 등
    // 그 외의 모든 "세션 없음" 경로는 기존대로 곧장 로그인 화면으로.
    if (onLogin || onSplash) return null;
    return AuthRoutes.phoneInput;
  }

  // PIN-forgot always needs a fresh re-signin mid-flow even though a
  // session already exists — let it run to completion; it exits via an
  // explicit context.go(home) on success, not via this redirect.
  if (onPinForgot) return null;

  // 소셜 로그인(구글)이나 게스트(익명) 세션은 PIN 게이트 자체를 건너뛴다
  // (사용자 요청 — 2026-08-31, 이전에는 게스트가 제외돼 PIN 설정 화면을
  // 보는 버그였다). `LoginNotifier.completeSocialLoginSession`이 PIN 없이
  // 곧장 역할 부여까지 처리하므로 hasPin/pinVerified는 이 세션 종류에서는
  // 애초에 의미가 없다 — 아래 두 검사를 그대로 통과시킨다.
  if (!skipsPinGate) {
    if (hasPin == null) {
      return AuthRoutes.sessionLoading;
    }

    if (!hasPin || !pinVerified) {
      if (onLogin) return null;
      return AuthRoutes.phoneInput;
    }
  }

  if (roles == null) {
    return AuthRoutes.sessionLoading;
  }

  if (roles.isEmpty) {
    return AuthRoutes.sessionLoading;
  }

  // `onLogin`만 확인하면 소셜 로그인처럼 role 부여가 비동기로 끝나
  // sessionLoading에 이미 가 있는 경우를 놓친다 — 그 경우 이 함수가
  // 계속 null(제자리 유지)을 반환해 role이 채워져도 영원히
  // sessionLoading에 멈춘다(2026-08-30 실기기에서 재현된 버그). "홈이
  // 아니면 홈으로"가 올바른 조건이다.
  if (location != AuthRoutes.home) return AuthRoutes.home;
  return null;
}
