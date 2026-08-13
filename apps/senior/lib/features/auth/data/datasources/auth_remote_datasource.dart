import 'package:supabase_flutter/supabase_flutter.dart';

/// Direct Supabase Auth SDK + `user_roles` table calls. Throws whatever the
/// SDK throws (`AuthException`/`PostgrestException`) — mapping those to
/// domain `Failure` is the Repository's job, not this DataSource's (see
/// api.md; note the SDK bypasses Dio/`DioClient`/`ErrorInterceptor`
/// entirely, so those Dio-specific rules don't apply to this file — the
/// Repository catches SDK exceptions directly instead).
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<void> requestOtp(String phoneNumber) {
    return _client.auth.signInWithOtp(phone: phoneNumber);
  }

  Future<void> verifyOtp({required String phoneNumber, required String otp}) {
    return _client.auth.verifyOTP(
      phone: phoneNumber,
      token: otp,
      type: OtpType.sms,
    );
  }

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
