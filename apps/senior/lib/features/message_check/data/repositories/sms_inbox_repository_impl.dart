import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/sms_message.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/repositories/sms_inbox_repository.dart';
import '../datasources/android_sms_datasource.dart';
import '../datasources/sms_permission_datasource.dart';

/// Real Android implementation — only ever constructed when
/// `Platform.isAndroid` is true (see `sms_inbox_repository_factory.dart`).
class SmsInboxRepositoryImpl implements SmsInboxRepository {
  const SmsInboxRepositoryImpl(this._permissionDataSource, this._smsDataSource);

  final SmsPermissionDataSource _permissionDataSource;
  final AndroidSmsDataSource _smsDataSource;

  @override
  Future<Result<SmsPermissionStatus>> checkPermission() async {
    try {
      return Ok(await _permissionDataSource.check());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<SmsPermissionStatus>> requestPermission() async {
    try {
      return Ok(await _permissionDataSource.request());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<List<SmsMessage>>> fetchRecentMessages() async {
    try {
      return Ok(await _smsDataSource.fetchRecent());
    } catch (_) {
      return const Err(UnknownFailure('최근 문자를 불러오지 못했어요.'));
    }
  }
}
