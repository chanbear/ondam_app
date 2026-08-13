import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as sms_inbox;

import '../../domain/entities/sms_message.dart';

/// Wraps `flutter_sms_inbox`'s `SmsQuery` — the only place in this feature
/// allowed to know that package exists. Read-only inbox query; this feature
/// never sends/composes SMS, so no send-related API is used here even
/// though some SMS packages expose one (kept out on purpose — smallest
/// permission/capability footprint for what Phase 7 actually needs).
///
/// Aliased on import (`as sms_inbox`) because the package's own message type
/// is also named `SmsMessage`, colliding with this feature's domain entity
/// of the same name.
///
/// Must only be constructed on Android — the plugin itself is Android-only.
class AndroidSmsDataSource {
  final sms_inbox.SmsQuery _query = sms_inbox.SmsQuery();

  /// Most-recent-first, capped at [count] so a large inbox never loads
  /// unbounded data into memory at once.
  Future<List<SmsMessage>> fetchRecent({int count = 50}) async {
    final messages = await _query.querySms(
      kinds: const [sms_inbox.SmsQueryKind.inbox],
      count: count,
    );
    return messages.map(_toDomain).toList();
  }

  SmsMessage _toDomain(sms_inbox.SmsMessage message) {
    final address = message.address;
    return SmsMessage(
      sender: (address != null && address.trim().isNotEmpty) ? address : null,
      body: message.body ?? '',
      receivedAt: message.date ?? DateTime.now(),
    );
  }
}
