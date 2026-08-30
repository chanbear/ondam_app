import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/notification_prefs_repository.dart';
import '../datasources/notification_prefs_remote_datasource.dart';

/// Same exception→Failure mapping pattern as `RegionRepositoryImpl`
/// (api.md Repository responsibility).
class NotificationPrefsRepositoryImpl implements NotificationPrefsRepository {
  const NotificationPrefsRepositoryImpl(this._dataSource);

  final NotificationPrefsRemoteDataSource _dataSource;

  @override
  Future<Result<bool>> getGuardianNotifyEnabled() async {
    try {
      final row = await _dataSource.fetchMine();
      final value = row?['guardian_notify_enabled'];
      // 컬럼 자체는 not-null default true지만, 행이 아예 없는 사용자(아직
      // upsertMine을 한 번도 호출 안 함)라면 row가 null일 수 있다 — 그때도
      // 서버 기본값과 같은 true로 취급한다(안전 우선 옵트아웃 설계).
      return Ok(value is bool ? value : true);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> setGuardianNotifyEnabled(bool enabled) async {
    try {
      await _dataSource.upsertMine(enabled: enabled);
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
