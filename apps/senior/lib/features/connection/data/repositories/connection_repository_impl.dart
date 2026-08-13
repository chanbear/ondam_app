import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/connection_token.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/connection_remote_datasource.dart';
import '../models/guardian_link_model.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as `AuthRepositoryImpl` (api.md Repository responsibility).
class ConnectionRepositoryImpl implements ConnectionRepository {
  const ConnectionRepositoryImpl(this._dataSource);

  final ConnectionRemoteDataSource _dataSource;

  @override
  Future<Result<ConnectionToken>> generateConnectionToken() async {
    try {
      final data = await _dataSource.generateConnectionToken();
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      return Ok(
        ConnectionToken(
          token: data['token'] as String,
          expiresAt: DateTime.parse(data['expiresAt'] as String),
        ),
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      return Err(_mapReason(reason));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<List<GuardianLink>>> getGuardianLinks() async {
    try {
      final rows = await _dataSource.fetchGuardianLinks();
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
  Future<Result<void>> respondToRequest({
    required String linkId,
    required bool accept,
  }) async {
    try {
      await _dataSource.updateStatus(
        linkId: linkId,
        status: accept
            ? GuardianLinkStatus.accepted.toDbValue()
            : GuardianLinkStatus.rejected.toDbValue(),
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> revokeLink(String linkId) async {
    try {
      await _dataSource.updateStatus(
        linkId: linkId,
        status: GuardianLinkStatus.revoked.toDbValue(),
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Failure _mapReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'server_error' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }

  Failure _mapPostgrestException(PostgrestException e) {
    if (e.code == 'PGRST301' || e.code == '42501') {
      // JWT expired / RLS denied — e.g. trying to accept/revoke a link this
      // user doesn't own, or an invalid status transition rejected by the
      // guardian_links_validate_update trigger.
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
