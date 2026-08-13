import 'dart:io' show Platform;

import '../../domain/repositories/sms_inbox_repository.dart';
import '../datasources/android_sms_datasource.dart';
import '../datasources/sms_permission_datasource.dart';
import 'sms_inbox_repository_impl.dart';
import 'unsupported_sms_inbox_repository_impl.dart';

/// Selects the platform-appropriate [SmsInboxRepository] implementation.
/// This is the one place in the feature that reads `Platform.isAndroid` —
/// isolating that platform check behind the repository boundary
/// (architecture principle: "platform dependency는 datasource/repository
/// 경계 뒤로 격리한다") so the DI/provider layer and everything above it
/// stays platform-agnostic.
SmsInboxRepository createSmsInboxRepository() {
  if (Platform.isAndroid) {
    return SmsInboxRepositoryImpl(
      SmsPermissionDataSource(),
      AndroidSmsDataSource(),
    );
  }
  return const UnsupportedSmsInboxRepositoryImpl();
}
