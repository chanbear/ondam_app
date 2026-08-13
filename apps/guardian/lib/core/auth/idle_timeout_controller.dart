import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_constants.dart';
import 'pin_verified_provider.dart';

/// Watches app foreground/background transitions and re-locks the PIN gate
/// (`pinVerifiedProvider.reset()`) if the app was backgrounded for at least
/// [guardianIdleTimeout]. Instantiated once at the app root (see app.dart)
/// — not per-screen, and not a StatefulWidget's local state, since it
/// drives a global routing decision (flutter.md: StatefulWidget is for
/// local UI state only).
class IdleTimeoutController {
  IdleTimeoutController(this._ref) {
    _listener = AppLifecycleListener(
      onHide: _onBackground,
      onPause: _onBackground,
      onResume: _onForeground,
    );
  }

  final Ref _ref;
  late final AppLifecycleListener _listener;
  DateTime? _backgroundedAt;

  void _onBackground() {
    _backgroundedAt ??= DateTime.now();
  }

  void _onForeground() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;

    if (shouldRelock(
      backgroundedAt: backgroundedAt,
      now: DateTime.now(),
      idleTimeout: guardianIdleTimeout,
    )) {
      _ref.read(pinVerifiedProvider.notifier).reset();
    }
  }

  void dispose() => _listener.dispose();
}

/// Pure decision function, split out from [IdleTimeoutController] so the
/// idle-timeout threshold logic is unit-testable without faking
/// `AppLifecycleListener`/Riverpod.
bool shouldRelock({
  required DateTime backgroundedAt,
  required DateTime now,
  required Duration idleTimeout,
}) {
  return now.difference(backgroundedAt) >= idleTimeout;
}

final idleTimeoutControllerProvider = Provider<IdleTimeoutController>((ref) {
  final controller = IdleTimeoutController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
