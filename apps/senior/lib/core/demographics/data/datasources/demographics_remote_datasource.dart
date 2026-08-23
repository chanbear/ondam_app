import 'package:supabase_flutter/supabase_flutter.dart';

/// `users` 테이블의 age/gender 컬럼만 읽고/쓴다 — `RegionRemoteDataSource`
/// 와 동일한 행(같은 PK)을 다루지만, PostgREST upsert는 요청 바디에 담긴
/// 컬럼만 갱신하므로 region_* 컬럼을 건드리지 않는다(반대도 마찬가지).
class DemographicsRemoteDataSource {
  const DemographicsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    return await _client.from('users').select().eq('id', userId).maybeSingle();
  }

  Future<void> upsertMine({required int age, required String gender}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    await _client.from('users').upsert({
      'id': userId,
      'age': age,
      'gender': gender,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
