/// Route path constants for the auth flow — shared between the router's
/// `redirect` logic (app_router.dart) and the auth feature's pages, which
/// need to `context.go(...)` between steps without hardcoding path strings
/// in multiple places.
abstract final class AuthRoutes {
  static const splash = '/auth/splash';
  static const phoneInput = '/auth/phone';
  static const pinSetup = '/auth/pin/setup';
  static const pinEntry = '/auth/pin/entry';
  static const pinForgot = '/auth/pin/forgot';
  static const roleSelect = '/auth/role-select';
  static const sessionLoading = '/auth/session-loading';
  static const home = '/';
}
