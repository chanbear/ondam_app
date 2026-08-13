import 'package:supabase_flutter/supabase_flutter.dart';

/// Elder-side `connection` calls: issuing a QR token via the
/// `create-connection-token` Edge Function, and reading/updating this
/// user's `guardian_links` rows directly through Postgrest (allowed by the
/// elder-scoped RLS policies — see
/// supabase/migrations/20260813000003_guardian_links_write_policies.sql).
/// Throws whatever the SDK throws; mapping to [Failure] is the Repository's
/// job (api.md).
class ConnectionRemoteDataSource {
  const ConnectionRemoteDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> generateConnectionToken() async {
    final response = await _client.functions.invoke('create-connection-token');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }

  Future<List<Map<String, dynamic>>> fetchGuardianLinks() async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('No active session');
    }
    final rows = await _client
        .from('guardian_links')
        .select()
        .eq('elder_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> updateStatus({
    required String linkId,
    required String status,
  }) async {
    await _client
        .from('guardian_links')
        .update({'status': status})
        .eq('id', linkId);
  }
}
