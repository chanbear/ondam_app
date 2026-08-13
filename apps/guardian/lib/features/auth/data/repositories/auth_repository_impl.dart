import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/pin_verify_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/pin_remote_datasource.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s. This is the
/// one place in the app allowed to know about `AuthException`/
/// `PostgrestException`/`FunctionException` (api.md's Repository
/// responsibility, adapted from Dio/NetworkException to the Supabase SDK
/// since Auth/Functions/Postgrest calls here bypass Dio entirely).
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource authDataSource,
    required PinRemoteDataSource pinDataSource,
  }) : _authDataSource = authDataSource,
       _pinDataSource = pinDataSource;

  final AuthRemoteDataSource _authDataSource;
  final PinRemoteDataSource _pinDataSource;

  @override
  Future<Result<void>> requestOtp(String phoneNumber) async {
    try {
      await _authDataSource.requestOtp(phoneNumber);
      return const Ok(null);
    } on AuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      await _authDataSource.verifyOtp(phoneNumber: phoneNumber, otp: otp);
      return const Ok(null);
    } on AuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _authDataSource.signOut();
      return const Ok(null);
    } on AuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> setPin(String pin) async {
    try {
      await _pinDataSource.setPin(pin);
      return const Ok(null);
    } on FunctionException catch (e) {
      return Err(_mapFunctionException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<PinVerifyResult>> verifyPin(String pin) async {
    try {
      final data = await _pinDataSource.verifyPin(pin);
      return _toPinVerifyResult(data);
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map) {
        return _toPinVerifyResult(Map<String, dynamic>.from(details));
      }
      return Err(_mapFunctionException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> resetPin(String pin) async {
    try {
      await _pinDataSource.resetPin(pin);
      return const Ok(null);
    } on FunctionException catch (e) {
      return Err(_mapFunctionException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<bool>> hasPin() async {
    try {
      final data = await _pinDataSource.hasPin();
      return Ok(data['hasPin'] == true);
    } on FunctionException catch (e) {
      return Err(_mapFunctionException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _pinDataSource.deleteAccount();
      return const Ok(null);
    } on FunctionException catch (e) {
      return Err(_mapFunctionException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> addRole(UserRole role) async {
    try {
      await _authDataSource.insertRole(role.toDbValue());
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<List<UserRole>>> getRoles() async {
    try {
      final rows = await _authDataSource.fetchRoles();
      return Ok(rows.map(UserRole.fromDbValue).toList());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (e) {
      return Err(_mapAuthException(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Result<PinVerifyResult> _toPinVerifyResult(Map<String, dynamic> json) {
    if (json['ok'] == true) {
      return const Ok(PinVerifyResult.success());
    }

    final reasonStr = json['reason'] as String?;
    if (reasonStr == 'missing_authorization' ||
        reasonStr == 'invalid_session') {
      return const Err(AuthFailure());
    }

    final reason = switch (reasonStr) {
      'pin_not_set' => PinVerifyFailureReason.pinNotSet,
      'wrong_pin' => PinVerifyFailureReason.wrongPin,
      'locked' => PinVerifyFailureReason.locked,
      'invalid_pin_format' => PinVerifyFailureReason.invalidFormat,
      _ => PinVerifyFailureReason.unknown,
    };
    final failedAttempts = json['failed_attempts'] as int?;
    final lockedUntilRaw = json['locked_until'] as String?;
    final lockedUntil = lockedUntilRaw != null
        ? DateTime.tryParse(lockedUntilRaw)
        : null;

    return Ok(
      PinVerifyResult.failure(
        reason: reason,
        failedAttempts: failedAttempts,
        lockedUntil: lockedUntil,
      ),
    );
  }

  Failure _mapFunctionException(FunctionException e) {
    final details = e.details;
    final reason = details is Map ? details['reason'] as String? : null;
    return switch (reason) {
      'invalid_pin_format' => const ValidationFailure('PIN은 4자리 숫자로 입력해주세요.'),
      'missing_authorization' ||
      'invalid_session' ||
      'reauthentication_required' => const AuthFailure(),
      'locked' => const AuthFailure('PIN이 잠겨 있습니다. 잠시 후 다시 시도해주세요.'),
      'server_error' => const ServerFailure(),
      _ => e.status == 0 ? const NetworkFailure() : const UnknownFailure(),
    };
  }

  Failure _mapAuthException(AuthException e) {
    if (e is AuthRetryableFetchException) {
      return const NetworkFailure();
    }
    final statusCode = int.tryParse(e.statusCode ?? '');
    if (statusCode == 401 || statusCode == 403) {
      return const AuthFailure();
    }
    if (statusCode != null && statusCode >= 500) {
      return const ServerFailure();
    }
    return ValidationFailure(e.message);
  }

  Failure _mapPostgrestException(PostgrestException e) {
    if (e.code == 'PGRST301' || e.code == '42501') {
      // JWT expired / RLS denied.
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
