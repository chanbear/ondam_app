import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as `AnalysisRepositoryImpl` (api.md Repository responsibility).
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._dataSource);

  final NotificationRemoteDataSource _dataSource;

  @override
  Future<Result<List<NotificationItem>>> getMyNotifications() async {
    try {
      final rows = await _dataSource.fetchMyNotifications();
      return Ok(
        rows.map((row) => NotificationModel.fromJson(row).toEntity()).toList(),
      );
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      final updated = await _dataSource.markRead(notificationId);
      if (!updated) {
        return const Err(ValidationFailure('알림을 찾을 수 없거나 접근 권한이 없어요.'));
      }
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Failure _mapPostgrestException(PostgrestException e) {
    if (e.code == 'PGRST301' || e.code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
