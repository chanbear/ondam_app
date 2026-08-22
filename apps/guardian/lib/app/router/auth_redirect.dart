import 'auth_routes.dart';

/// Pure decision function for the auth `redirect` state machine — kept
/// separate from `app_router.dart`'s provider-reading glue so the 3-state
/// model (technical-decisions.md §1-3-A) is unit-testable without faking
/// Supabase/Riverpod. Returns the path to redirect to, or `null` to allow
/// [location] as-is.
String? decideAuthRedirect({
  required bool hasSession,
  required bool? hasPin,
  required bool pinVerified,
  required List<Object>? roles,
  required String location,
}) {
  final onPhoneInput = location == AuthRoutes.phoneInput;
  final onPinSetup = location == AuthRoutes.pinSetup;
  final onPinEntry = location == AuthRoutes.pinEntry;
  final onPinForgot = location == AuthRoutes.pinForgot;
  final onRoleSelect = location == AuthRoutes.roleSelect;
  final onAuthFlow =
      onPhoneInput || onPinSetup || onPinEntry || onPinForgot || onRoleSelect;

  if (!hasSession) {
    if (onPhoneInput) return null;
    return AuthRoutes.phoneInput;
  }

  // PIN-forgot always needs a fresh re-signin mid-flow even though a
  // session already exists — let it run to completion; it exits via an
  // explicit context.go(home) on success, not via this redirect.
  if (onPinForgot) return null;

  if (hasPin == null) {
    return AuthRoutes.sessionLoading;
  }

  if (!hasPin) {
    if (onPinSetup) return null;
    return AuthRoutes.pinSetup;
  }

  if (!pinVerified) {
    if (onPinEntry) return null;
    return AuthRoutes.pinEntry;
  }

  if (roles == null) {
    return AuthRoutes.sessionLoading;
  }

  if (roles.isEmpty) {
    if (onRoleSelect) return null;
    return AuthRoutes.roleSelect;
  }

  if (onAuthFlow) return AuthRoutes.home;
  return null;
}
