import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central access point for environment configuration.
/// Values come from .env (loaded in main.dart before runApp) — never hardcode
/// API URLs or keys directly in source.
abstract final class AppConfig {
  /// Supabase project URL and anon (public) key. The anon key is safe to
  /// ship in a client app — it is meant to be public and is constrained by
  /// RLS. Never add the service_role key here.
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  /// 카카오 로컬 API(REST) 키 — 웹에서 좌표→행정구역 역지오코딩에 쓴다
  /// (`geocoding` 패키지는 웹 구현이 없어서 네이티브 플랫폼에서만 쓸 수
  /// 있다). 카카오 로그인용 키와는 별개다.
  static String get kakaoRestApiKey =>
      dotenv.get('KAKAO_REST_API_KEY', fallback: '');
}
