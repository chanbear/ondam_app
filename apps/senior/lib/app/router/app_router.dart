import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state_provider.dart';
import '../../core/auth/pin_verified_provider.dart';
import '../../core/auth/supabase_client_provider.dart';
import '../../features/auth/presentation/pages/phone_input_page.dart';
import '../../features/auth/presentation/pages/pin_forgot_page.dart';
import '../../features/auth/presentation/pages/session_loading_page.dart';
import '../../features/auth/presentation/providers/has_pin_provider.dart';
import '../../features/auth/presentation/providers/role_notifier.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import 'auth_redirect.dart';
import 'auth_routes.dart';

/// Central route table for the Senior app, gated by the 3-state auth model
/// (technical-decisions.md §1-3-A), simplified for ONDAM 2.0V(요구사항
/// 2/3/4) — phone+password login, first-time PIN setup and PIN re-entry all
/// happen on the SAME `phoneInput` screen (LoginNotifier orchestrates them
/// internally), and role is decided automatically instead of a separate
/// selection screen:
///   No session, or session but PIN not set/verified -> phone input (login)
///   Session, PIN verified, role not yet auto-added -> session loading
///   Session, PIN verified, role present -> home
/// `pin_setup_page.dart`/`pin_entry_page.dart`/`role_select_page.dart` are
/// intentionally left in place (unregistered) rather than deleted — see
/// PHASE 21 report.
/// This router is independent from the Guardian app's — the two apps never
/// share a router (architecture.md).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
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
        path: AuthRoutes.pinForgot,
        builder: (context, state) => const PinForgotPage(),
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
