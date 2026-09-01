import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/demo_usage_stats.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/connection_remote_datasource.dart';
import '../models/guardian_link_model.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as `AuthRepositoryImpl` (api.md Repository responsibility).
class ConnectionRepositoryImpl implements ConnectionRepository {
  const ConnectionRepositoryImpl(this._dataSource);

  final ConnectionRemoteDataSource _dataSource;

  @override
  Future<Result<GuardianLink>> redeemConnectionToken(String token) async {
    try {
      final data = await _dataSource.redeemConnectionToken(token);
      if (data['ok'] != true) {
        return Err(_mapRedeemReason(data['reason'] as String?));
      }
      final linkId = data['linkId'] as String;
      final row = await _dataSource.fetchLinkById(linkId);
      return Ok(GuardianLinkModel.fromJson(row).toEntity());
    } on FunctionException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      return Err(_mapRedeemReason(reason));
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<List<GuardianLink>>> getMyLinks() async {
    try {
      final rows = await _dataSource.fetchMyLinks();
      return Ok(
        rows.map((row) => GuardianLinkModel.fromJson(row).toEntity()).toList(),
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
  Future<Result<void>> revokeLink(String linkId) async {
    try {
      await _dataSource.revokeLink(linkId);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<DemoUsageStats?>> getDemoUsageStats(String elderId) async {
    try {
      final row = await _dataSource.fetchDemoUsageStats(elderId);
      if (row == null) return const Ok(null);
      return Ok(
        DemoUsageStats(
          since: DateTime.parse(row['since'] as String),
          analysisCount: row['analysis_count'] as int,
        ),
      );
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Failure _mapRedeemReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'invalid_token' => const ValidationFailure('QR 코드를 다시 확인해주세요.'),
      'token_expired' => const ValidationFailure(
        'QR 코드가 만료됐어요. 어르신께 새 QR을 요청해주세요.',
      ),
      'token_already_used' => const ValidationFailure('이미 사용된 QR 코드예요.'),
      'self_link_not_allowed' => const ValidationFailure(
        '본인에게는 연결을 요청할 수 없어요.',
      ),
      'invalid_token_format' => const ValidationFailure('QR 코드를 다시 확인해주세요.'),
      'server_error' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }

  Failure _mapPostgrestException(PostgrestException e) {
    if (e.code == 'PGRST301' || e.code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
