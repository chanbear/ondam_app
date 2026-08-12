import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central access point for environment configuration.
/// Values come from .env (loaded in main.dart before runApp) — never hardcode
/// API URLs or keys directly in source.
abstract final class AppConfig {
  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: '');
}
