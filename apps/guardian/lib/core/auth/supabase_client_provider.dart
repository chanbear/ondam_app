import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared Supabase client instance. `Supabase.initialize()` runs once in
/// `main.dart` before `runApp` — this provider exposes that singleton to
/// Riverpod so feature datasources depend on `ref.watch(...)` like every
/// other dependency instead of reaching for `Supabase.instance` directly.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
