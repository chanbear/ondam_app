import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state_provider.dart';
import '../../core/auth/pin_verified_provider.dart';
import '../../core/auth/supabase_client_provider.dart';
import '../../features/auth/presentation/pages/phone_input_page.dart';
import '../../features/auth/presentation/pages/pin_entry_page.dart';
import '../../features/auth/presentation/pages/pin_forgot_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/auth/presentation/pages/role_select_page.dart';
import '../../features/auth/presentation/pages/session_loading_page.dart';
import '../../features/auth/presentation/providers/has_pin_provider.dart';
import '../../features/auth/presentation/providers/role_notifier.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import 'auth_redirect.dart';
import 'auth_routes.dart';
import 'root_navigator_key.dart';

/// Central route table for the Guardian app, gated by the 3-state auth
/// model (technical-decisions.md §1-3-A):
///   No Session            -> phone input (name + phone, no OTP)
///   Session, PIN unset    -> PIN setup
///   Session, PIN unverified -> PIN entry
///   Session, PIN verified, no role -> role selection
///   Session, PIN verified, has role -> home
/// This router is independent from the Senior app's — the two apps never
/// share a router (architecture.md).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AuthRoutes.phoneInput,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AuthRoutes.home,
        builder: (context, state) => const HomeShellPage(),
      ),
      GoRoute(
        path: AuthRoutes.phoneInput,
        builder: (context, state) => const PhoneInputPage(),
      ),
      GoRoute(
        path: AuthRoutes.pinSetup,
        builder: (context, state) => const PinSetupPage(),
      ),
      GoRoute(
        path: AuthRoutes.pinEntry,
        builder: (context, state) => const PinEntryPage(),
      ),
      GoRoute(
        path: AuthRoutes.pinForgot,
        builder: (context, state) => const PinForgotPage(),
      ),
      GoRoute(
        path: AuthRoutes.roleSelect,
        builder: (context, state) => const RoleSelectPage(),
      ),
      GoRoute(
        path: AuthRoutes.sessionLoading,
        builder: (context, state) => const SessionLoadingPage(),
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundPage(),
  );
});

String? _redirect(Ref ref, GoRouterState state) {
  final hasSession =
      ref.read(supabaseClientProvider).auth.currentSession != null;

  return decideAuthRedirect(
    hasSession: hasSession,
    hasPin: ref.read(hasPinProvider).value,
    pinVerified: ref.read(pinVerifiedProvider),
    roles: ref.read(roleNotifierProvider).value,
    location: state.matchedLocation,
  );
}

/// Bridges Riverpod state changes to go_router's `refreshListenable`, so
/// `redirect` re-runs whenever session/PIN-gate/role state changes — this
/// is the standard Riverpod+go_router integration pattern (`ref.listen`
/// works outside widget `build()`, directly inside a Provider callback).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
    ref.listen(pinVerifiedProvider, (_, _) => notifyListeners());
    ref.listen(hasPinProvider, (_, _) => notifyListeners());
    ref.listen(roleNotifierProvider, (_, _) => notifyListeners());
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('404 — 페이지를 찾을 수 없습니다.')));
  }
}
