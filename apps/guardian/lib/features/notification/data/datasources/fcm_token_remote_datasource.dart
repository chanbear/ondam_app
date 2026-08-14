import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes to `fcm_tokens` (id, user_id, token, device_info, updated_at). As
/// of this Phase the table does not exist yet in `supabase/migrations/` —
/// Backend owns creating it (technical-decisions.md §4). Calls below will
/// throw a `PostgrestException` (undefined table) until that migration
/// lands. Throws whatever the SDK throws; mapping to [Failure] is the
/// Repository's job (api.md).
///
/// No DB-level unique constraint on `token` is assumed (the migration
/// doesn't exist yet to confirm one) — `upsertToken` reads-then-decides
/// insert vs. update itself instead of relying on a Postgrest `upsert`
/// `onConflict` target that may not exist.
class FcmTokenRemoteDataSource {
  const FcmTokenRemoteDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> upsertToken({
    required String token,
    required Map<String, dynamic> deviceInfo,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('No active session');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await _client
        .from('fcm_tokens')
        .select('id')
        .eq('token', token)
        .maybeSingle();

    if (existing == null) {
      await _client.from('fcm_tokens').insert({
        'user_id': userId,
        'token': token,
        'device_info': deviceInfo,
        'updated_at': now,
      });
    } else {
      await _client
          .from('fcm_tokens')
          .update({
            'user_id': userId,
            'device_info': deviceInfo,
            'updated_at': now,
          })
          .eq('token', token);
    }
  }

  /// `.select()` after `.delete()` asks PostgREST to return the deleted
  /// rows (`Prefer: return=representation`) instead of an empty body, so an
  /// RLS-blocked or already-gone delete (0 rows) is distinguishable from an
  /// actual deletion — without this, `fcm_tokens_delete_own`
  /// (20260814000004) matching 0 rows would look identical to success.
  Future<bool> deleteToken(String token) async {
    final deleted = await _client
        .from('fcm_tokens')
        .delete()
        .eq('token', token)
        .select('id');
    return (deleted as List).isNotEmpty;
  }
}
