import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// OAuth 로그인 완료 후 브라우저가 앱으로 돌아오는 딥링크 scheme. 실제
/// 앱에도(`android/app/src/main/AndroidManifest.xml`의 intent-filter) 같은
/// scheme/host로 등록돼 있고, Supabase 대시보드 Authentication → URL
/// Configuration의 Redirect URLs에도 이 값을 그대로 추가해야 한다 —
/// 등록하지 않으면 로그인은 성공해도 앱으로 돌아오지 못한다.
const oauthRedirectUrl = 'io.ondam.senior://login-callback';

/// 웹에는 커스텀 scheme으로 돌아올 네이티브 앱이 없다 — 대신 지금 이
/// 페이지를 서빙한 origin+경로 그대로로 돌아온다. 이 값도(배포 경로가
/// 바뀔 때마다) Supabase Redirect URLs에 등록되어 있어야 한다.
String get _webOauthRedirectUrl => Uri.base.origin + Uri.base.path;

/// Direct Supabase Auth SDK + `user_roles` table calls. Throws whatever the
/// SDK throws (`AuthException`/`PostgrestException`) — mapping those to
/// domain `Failure` is the Repository's job, not this DataSource's (see
/// api.md; note the SDK bypasses Dio/`DioClient`/`ErrorInterceptor`
/// entirely, so those Dio-specific rules don't apply to this file — the
/// Repository catches SDK exceptions directly instead).
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Calls the `signup-with-phone` Edge Function (creates or finds the user
  /// by phone, no OTP) and establishes the session from the refresh token
  /// it returns.
  Future<void> signUp({
    required String name,
    required String phoneNumber,
  }) async {
    final response = await _client.functions.invoke(
      'signup-with-phone',
      body: {'name': name, 'phone': phoneNumber},
    );
    final data = response.data;
    if (data is! Map || data['ok'] != true || data['refreshToken'] is! String) {
      throw FunctionException(status: response.status, details: data);
    }
    await _client.auth.setSession(data['refreshToken'] as String);
  }

  /// Launches the system browser for [provider]'s consent screen. The
  /// redirect URI must match a URL Configuration entry registered in the
  /// Supabase Dashboard (Authentication → URL Configuration) — see
  /// `oauthRedirectUrl` doc comment for the exact scheme this app registers
  /// in `AndroidManifest.xml`/iOS `Info.plist`.
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? _webOauthRedirectUrl : oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
      // Supabase의 카카오 기본 스코프는 account_email까지 포함하는데,
      // 카카오 콘솔에서 account_email은 사업자 정보 등록 전이라 아직
      // 승인 불가 상태(개인 개발자 비즈 앱은 사업자 번호 없이는 신청
      // 자체가 막힘) — 승인 안 된 스코프가 하나라도 섞이면 카카오가
      // 요청 전체를 거부한다(KOE205 "잘못된 요청"). 승인된 두 스코프만
      // 명시해서 우회한다.
      scopes: provider == OAuthProvider.kakao
          ? 'profile_nickname profile_image'
          : null,
    );
  }

  Future<void> signInAsGuest() => _client.auth.signInAnonymously();

  Future<void> signOut() => _client.auth.signOut();

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> insertRole(String roleDbValue) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('No active session');
    }
    await _client.from('user_roles').insert({
      'user_id': userId,
      'role': roleDbValue,
    });
  }

  Future<List<String>> fetchRoles() async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('No active session');
    }
    final rows = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId);
    return rows.map((row) => row['role'] as String).toList();
  }
}
