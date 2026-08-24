import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads `schedules` for one elder. Access is entirely governed by that
/// table's RLS (elder self / accepted guardian only, see
/// supabase/migrations/20260824000001_create_schedules.sql) — this class
/// does not filter by connection status itself, it just issues the query and
/// lets Postgrest/RLS decide what rows come back (an unconnected or
/// pending/rejected/revoked elder_id simply returns zero rows, not an
/// error). Guardian is read-only — no create/update/delete here (same
/// pattern as `AnalysisRemoteDataSource`). Throws whatever the SDK throws;
/// mapping to [Failure] is the Repository's job (api.md).
class ScheduleRemoteDataSource {
  const ScheduleRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchForElder(String elderId) async {
    final rows = await _client
        .from('schedules')
        .select()
        .eq('elder_id', elderId)
        .order('scheduled_at');
    return List<Map<String, dynamic>>.from(rows);
  }
}
