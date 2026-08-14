import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/updates `notifications` for the current user. As of this Phase the
/// table does not exist yet in `supabase/migrations/` — Backend owns
/// creating it (technical-decisions.md §4). Queries below will throw a
/// `PostgrestException` (undefined table) until that migration lands; that
/// is expected and is why `NotificationRepositoryImpl` maps failures instead
/// of assuming success. Throws whatever the SDK throws; mapping to
/// [Failure] is the Repository's job (api.md).
class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchMyNotifications() async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('No active session');
    }
    final rows = await _client
        .from('notifications')
        .select()
        .eq('target_user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// `notifications` has no client UPDATE RLS policy (by design — see
  /// 20260814000002) so a plain `.update()` here would silently match 0
  /// rows and look like success. `mark_notification_read` is a
  /// SECURITY DEFINER RPC (20260814000004) that only ever touches
  /// `read_at` on a row the caller owns (`target_user_id = auth.uid()`)
  /// and returns whether it actually found+owned that row — surface that
  /// boolean instead of assuming success.
  Future<bool> markRead(String notificationId) async {
    final result = await _client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
    return result as bool;
  }
}
