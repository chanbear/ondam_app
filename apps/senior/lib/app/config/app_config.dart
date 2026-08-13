import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central access point for environment configuration.
/// Values come from .env (loaded in main.dart before runApp) — never hardcode
/// API URLs or keys directly in source.
abstract final class AppConfig {
  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: '');

  /// Supabase project URL and anon (public) key. The anon key is safe to
  /// ship in a client app — it is meant to be public and is constrained by
  /// RLS. Never add the service_role key here.
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
}
