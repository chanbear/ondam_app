import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/auth/auth_state_provider.dart';
import 'auth_di_providers.dart';

/// Router-support cache: "does the signed-in user already have a PIN set".
/// The router reads this (never the raw network call directly) to decide
/// PIN-setup vs PIN-entry. Invalidated after a successful `set_pin`/
/// `reset_pin` call (see PinNotifier).
///
/// Also re-fetches on every `authStateChangesProvider` event (PHASE 38 —
/// same fix as Senior's `hasPinProvider`, see its doc comment for the full
/// root-cause writeup: a one-shot `FutureProvider` can permanently cache a
/// swallowed transient error as `false` if its first resolution races a
/// still-settling restored session at app boot, and nothing but this
/// provider's own dependency graph would ever re-run it since sign-in
/// itself never explicitly invalidates it).
final hasPinProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateChangesProvider);
  final result = await ref.read(hasPinUseCaseProvider).call();
  return switch (result) {
    Ok(:final value) => value,
    Err() => false,
  };
});
