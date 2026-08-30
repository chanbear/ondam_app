import '../../domain/repositories/sms_inbox_repository.dart';
import '../datasources/android_sms_datasource.dart';
import '../datasources/sms_permission_datasource.dart';
import 'platform/android_platform.dart';
import 'sms_inbox_repository_impl.dart';
import 'unsupported_sms_inbox_repository_impl.dart';

/// Selects the platform-appropriate [SmsInboxRepository] implementation.
/// This is the one place in the feature that reads the Android platform
/// check — isolating it behind the repository boundary (architecture
/// principle: "platform dependency는 datasource/repository 경계 뒤로
/// 격리한다") so the DI/provider layer and everything above it stays
/// platform-agnostic. `isAndroidPlatform` (not `dart:io` directly) because
/// web has no `dart:io` — see platform/android_platform.dart.
SmsInboxRepository createSmsInboxRepository() {
  if (isAndroidPlatform) {
    return SmsInboxRepositoryImpl(
      SmsPermissionDataSource(),
      AndroidSmsDataSource(),
    );
  }
  return const UnsupportedSmsInboxRepositoryImpl();
}
