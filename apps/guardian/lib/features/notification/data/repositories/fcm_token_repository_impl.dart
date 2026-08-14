import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/fcm_token_repository.dart';
import '../datasources/fcm_token_remote_datasource.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as `AnalysisRepositoryImpl` (api.md Repository responsibility).
class FcmTokenRepositoryImpl implements FcmTokenRepository {
  const FcmTokenRepositoryImpl(this._dataSource);

  final FcmTokenRemoteDataSource _dataSource;

  @override
  Future<Result<void>> registerToken({
    required String token,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      await _dataSource.upsertToken(token: token, deviceInfo: deviceInfo);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> invalidateToken(String token) async {
    try {
      final deleted = await _dataSource.deleteToken(token);
      if (!deleted) {
        return const Err(ValidationFailure('토큰을 찾을 수 없거나 이미 삭제되었어요.'));
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
