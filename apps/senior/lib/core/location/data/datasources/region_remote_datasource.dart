import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes the signed-in user's own row in `users`
/// (technical-decisions.md §4 `users` 스케치 — 이번 phase에서 region 관련
/// 컬럼만 실제로 생성한다, `supabase/migrations/20260819000002_create_users_region.sql`).
/// Access is entirely governed by the `users_select_own`/`users_upsert_own`
/// RLS policies (`id = auth.uid()`) — throws whatever the SDK throws;
/// mapping to `Failure` is the Repository's job (api.md).
class RegionRemoteDataSource {
  const RegionRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    return await _client.from('users').select().eq('id', userId).maybeSingle();
  }

  Future<void> upsertMine({
    required String sido,
    required String sigungu,
    required String dong,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    await _client.from('users').upsert({
      'id': userId,
      'region_sido': sido,
      'region_sigungu': sigungu,
      'region_dong': dong,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
