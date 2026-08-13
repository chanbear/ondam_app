import 'package:ondam_core/ondam_core.dart';

import '../entities/sms_message.dart';
import '../entities/sms_permission_status.dart';

/// Automatic SMS-inbox access — Android-only capability today (§ Phase 7
/// decision: iOS has no automatic access, see `message_risk_repository.dart`
/// for the platform-agnostic analysis step both flows converge on).
///
/// A non-Android implementation of this interface must still exist (rather
/// than the presentation layer branching on `Platform.isAndroid` itself) so
/// callers stay platform-agnostic — it always resolves permission as
/// [SmsPermissionStatus.unsupported] and never returns real inbox data. This
/// interface intentionally only covers a one-shot recent-messages fetch, not
/// a live "new message" stream — extending to that later (e.g. a
/// `Stream<SmsMessage> watchIncoming()` method) does not require reshaping
/// this contract, but is out of scope for this Phase (no unrequested
/// background service).
abstract class SmsInboxRepository {
  Future<Result<SmsPermissionStatus>> checkPermission();

  Future<Result<SmsPermissionStatus>> requestPermission();

  Future<Result<List<SmsMessage>>> fetchRecentMessages();
}
