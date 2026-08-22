import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/auth/auth_state_provider.dart';
import 'auth_di_providers.dart';

/// Router-support cache: "does the signed-in user already have a PIN set".
/// The router reads this (never the raw network call directly) to decide
/// PIN-setup vs PIN-entry. Invalidated after a successful `set_pin`/
/// `reset_pin` call (see PinNotifier).
///
/// Also re-fetches on every `authStateChangesProvider` event (PHASE 38 버그
/// 수정): a plain one-shot `FutureProvider` only ever resolves once and then
/// caches that result forever, including a transient error swallowed by the
/// `Err() => false` fallback below. If that first resolution races a
/// restored-session's token still settling at app boot and loses, this
/// provider permanently caches `false` — and since login (`signUp` in
/// `LoginNotifier`) never explicitly invalidates it (only `setPin`/
/// `resetPin` do), a real, successful login on that session would still see
/// the router's `hasPin` stuck at the stale `false` forever, redirecting
/// back to the login screen in an infinite loop with no visible error
/// (verified against a real device: `verify-pin` succeeds server-side every
/// time, but the stale cached `false` here keeps `decideAuthRedirect`
/// sending it back to `phoneInput`). Watching the auth-change stream makes
/// every sign-in/sign-out/token-refresh recompute this from scratch, so a
/// stale cache can never outlive the session it was wrong about.
final hasPinProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateChangesProvider);
  final result = await ref.read(hasPinUseCaseProvider).call();
  return switch (result) {
    Ok(:final value) => value,
    Err() => false,
  };
});
