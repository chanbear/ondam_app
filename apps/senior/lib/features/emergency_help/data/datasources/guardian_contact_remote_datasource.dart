import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the connected guardian's phone number via `get_connected_guardian_phone`
/// (`supabase/migrations/20260821000001_guardian_contact_phone.sql`) — a
/// SECURITY DEFINER RPC, the only path to it since `auth.users` (where
/// phone actually lives) has no client-facing SELECT policy. Throws
/// whatever the SDK throws; mapping to [Failure] is the Repository's job
/// (api.md).
class GuardianContactRemoteDataSource {
  const GuardianContactRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<String?> fetchGuardianPhone() async {
    final result = await _client.rpc('get_connected_guardian_phone');
    return result as String?;
  }
}
