import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/sms_message.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/repositories/sms_inbox_repository.dart';

/// Non-Android fallback (iOS today). There is no automatic SMS-inbox access
/// on this platform by design (Phase 7 decision) — this never wraps a real
/// platform API and never returns fabricated messages. Permission always
/// resolves to [SmsPermissionStatus.unsupported]; presentation must route to
/// the manual-input flow instead of ever calling [fetchRecentMessages].
class UnsupportedSmsInboxRepositoryImpl implements SmsInboxRepository {
  const UnsupportedSmsInboxRepositoryImpl();

  @override
  Future<Result<SmsPermissionStatus>> checkPermission() async {
    return const Ok(SmsPermissionStatus.unsupported);
  }

  @override
  Future<Result<SmsPermissionStatus>> requestPermission() async {
    return const Ok(SmsPermissionStatus.unsupported);
  }

  @override
  Future<Result<List<SmsMessage>>> fetchRecentMessages() async {
    return const Err(UnavailableFailure('이 기기에서는 문자 자동 확인을 지원하지 않아요.'));
  }
}
