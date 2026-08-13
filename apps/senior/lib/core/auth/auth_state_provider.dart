import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

/// Live stream of Supabase Auth state changes. The router listens to this
/// (via its refresh notifier in app_router.dart) to re-run its `redirect`
/// callback whenever the session appears/disappears — session lifecycle
/// itself stays fully owned by the SDK (technical-decisions.md §1-3-A:
/// "Session ≠ PIN Gate"), this just surfaces it to Riverpod/go_router.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});
