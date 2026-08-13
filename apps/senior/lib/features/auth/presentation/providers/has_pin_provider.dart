import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import 'auth_di_providers.dart';

/// Router-support cache: "does the signed-in user already have a PIN set".
/// The router reads this (never the raw network call directly) to decide
/// PIN-setup vs PIN-entry. Invalidated after a successful `set_pin`/
/// `reset_pin` call (see PinNotifier) and implicitly recomputed whenever a
/// new session starts, since app_router.dart's redirect only consults it
/// once a session exists.
final hasPinProvider = FutureProvider<bool>((ref) async {
  final result = await ref.read(hasPinUseCaseProvider).call();
  return switch (result) {
    Ok(:final value) => value,
    Err() => false,
  };
});
