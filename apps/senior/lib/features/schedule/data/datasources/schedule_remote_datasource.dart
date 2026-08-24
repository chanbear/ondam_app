import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD on `schedules` for the currently signed-in user only. Access is
/// entirely governed by the `schedules_select_elder`/`schedules_insert_elder`/
/// `schedules_update_elder`/`schedules_delete_elder` RLS policies (elder_id =
/// auth.uid(), see supabase/migrations/20260824000001_create_schedules.sql)
/// — this class additionally filters by `elder_id` itself as defense in
/// depth, using the id from the caller's own session, never a caller-supplied
/// value (same pattern as `AnalysisRecordsRemoteDataSource`). Throws
/// whatever the SDK throws; mapping to `Failure` is the Repository's job
/// (api.md).
class ScheduleRemoteDataSource {
  const ScheduleRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }

    final rows = await _client
        .from('schedules')
        .select()
        .eq('elder_id', userId)
        .order('scheduled_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// [recurrenceHour]/[recurrenceMinute]는 [isRecurring]이 true일 때만
  /// 채운다(유효성 검증 자체는 domain의 `CreateScheduleUseCase` 책임).
  Future<void> create({
    required String title,
    required DateTime scheduledAt,
    required bool isRecurring,
    int? recurrenceHour,
    int? recurrenceMinute,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }

    await _client.from('schedules').insert({
      'elder_id': userId,
      'title': title,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_time': isRecurring
          ? _formatTime(recurrenceHour!, recurrenceMinute!)
          : null,
    });
  }

  Future<void> toggleCompleted(String id, bool completed) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }

    await _client
        .from('schedules')
        .update({'completed': completed})
        .eq('id', id)
        .eq('elder_id', userId);
  }

  Future<void> delete(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }

    await _client
        .from('schedules')
        .delete()
        .eq('id', id)
        .eq('elder_id', userId);
  }

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
}
