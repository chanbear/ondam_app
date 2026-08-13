import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads `analysis_results` for one elder. Access is entirely governed by
/// that table's RLS (elder self / accepted guardian only) — this class does
/// not filter by connection status itself, it just issues the query and
/// lets Postgrest/RLS decide what rows come back (an unconnected or
/// pending/rejected/revoked elder_id simply returns zero rows, not an
/// error). Throws whatever the SDK throws; mapping to [Failure] is the
/// Repository's job (api.md).
class AnalysisRemoteDataSource {
  const AnalysisRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchForElder(String elderId) async {
    final rows = await _client
        .from('analysis_results')
        .select()
        .eq('elder_id', elderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
