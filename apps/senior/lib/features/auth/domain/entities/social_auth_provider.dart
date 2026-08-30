/// Third-party 로그인 제공자. Supabase Auth가 기본 지원하는 provider만
/// 나열한다 — Naver는 Supabase의 기본 OAuth provider 목록에 없어(2026-08-30
/// 기준) 별도 custom OIDC 연동이 필요하므로 이 enum에 없다.
enum SocialAuthProvider { google, kakao }
