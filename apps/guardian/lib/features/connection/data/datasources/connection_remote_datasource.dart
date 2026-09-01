import 'package:supabase_flutter/supabase_flutter.dart';

/// Guardian-side `connection` calls: redeeming a scanned QR token via the
/// `redeem-connection-token` Edge Function, and reading/updating this
/// user's `guardian_links` rows directly through Postgrest (allowed by the
/// guardian-scoped RLS policies — see
/// supabase/migrations/20260813000003_guardian_links_write_policies.sql).
/// Throws whatever the SDK throws; mapping to [Failure] is the Repository's
/// job (api.md).
class ConnectionRemoteDataSource {
  const ConnectionRemoteDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> redeemConnectionToken(String token) async {
    final response = await _client.functions.invoke(
      'redeem-connection-token',
      body: {'token': token},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }

  Future<List<Map<String, dynamic>>> fetchMyLinks() async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('No active session');
    }
    final rows = await _client
        .from('guardian_links')
        .select()
        .eq('guardian_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> fetchLinkById(String linkId) async {
    final row = await _client
        .from('guardian_links')
        .select()
        .eq('id', linkId)
        .single();
    return row;
  }

  Future<void> revokeLink(String linkId) async {
    await _client
        .from('guardian_links')
        .update({'status': 'revoked'})
        .eq('id', linkId);
  }

  Future<Map<String, dynamic>?> fetchDemoUsageStats(String elderId) async {
    return _client
        .from('demo_usage_stats')
        .select()
        .eq('elder_id', elderId)
        .maybeSingle();
  }
}
