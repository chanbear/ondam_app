import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Memory-only PIN gate. Deliberately NOT persisted anywhere (no
/// SecureStorage, no SharedPreferences, no file, no SQLite — see
/// technical-decisions.md §1-3-A "Session ≠ PIN Gate" and storage policy).
/// Resets to `false` on: app cold start (initial state), sign-out, and
/// idle timeout (see idle_timeout_controller.dart).
class PinVerifiedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markVerified() => state = true;

  void reset() => state = false;
}

final pinVerifiedProvider = NotifierProvider<PinVerifiedNotifier, bool>(
  PinVerifiedNotifier.new,
);
