/// Third-party 로그인 제공자. 2026-08-31 — 사용자 요청으로 카카오 로그인을
/// 제거(네이버는 애초에 이 enum에 없던 UI 전용 "준비 중" 버튼이었다 —
/// `phone_input_page.dart` 참고). 구글만 남는다.
enum SocialAuthProvider { google }
