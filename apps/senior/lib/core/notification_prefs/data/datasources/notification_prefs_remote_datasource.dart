import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes the signed-in user's own `guardian_notify_enabled` column in
/// `users` (`supabase/migrations/20260831000001_users_guardian_notify_enabled.sql`).
/// Access is entirely governed by the `users_select_own`/`users_update_own`
/// RLS policies (`id = auth.uid()`) — throws whatever the SDK throws; mapping
/// to `Failure` is the Repository's job (api.md). Same shape as
/// `RegionRemoteDataSource`/`ProfileRemoteDataSource`.
class NotificationPrefsRemoteDataSource {
  const NotificationPrefsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    return await _client
        .from('users')
        .select('guardian_notify_enabled')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> upsertMine({required bool enabled}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    await _client.from('users').upsert({
      'id': userId,
      'guardian_notify_enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
