import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads `analysis_results` for the currently signed-in user only. Access
/// is entirely governed by the `analysis_results_select_elder` RLS policy
/// (`elder_id = auth.uid()`, see
/// supabase/migrations/20260814000001_create_analysis_results.sql) — this
/// class additionally filters by `elder_id` itself as defense in depth
/// (never trust RLS alone to be the only thing standing between "my
/// records" and "everyone's records"), using the id from the caller's own
/// session, never a caller-supplied value. Throws whatever the SDK throws;
/// mapping to `Failure` is the Repository's job (api.md).
class AnalysisRecordsRemoteDataSource {
  const AnalysisRecordsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }

    final rows = await _client
        .from('analysis_results')
        .select()
        .eq('elder_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// `confirmed_at`만 쓸 수 있도록 컬럼 권한으로 좁혀져 있다(migration
  /// 20260819000001 참고) — 다른 컬럼을 함께 보내도 서버가 거부한다.
  Future<void> confirm(String analysisResultId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    await _client
        .from('analysis_results')
        .update({'confirmed_at': DateTime.now().toIso8601String()})
        .eq('id', analysisResultId)
        .eq('elder_id', userId);
  }
}
