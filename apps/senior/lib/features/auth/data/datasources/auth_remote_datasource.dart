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
