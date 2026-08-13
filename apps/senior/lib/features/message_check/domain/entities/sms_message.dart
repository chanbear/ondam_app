/// A text message to be checked for risk — either read from the Android SMS
/// inbox, or typed/pasted manually (iOS, or Android manual entry). Pure
/// value type, no platform package dependency (domain layer rule).
///
/// [sender] is null for manually entered text, where there is no sender
/// concept — presentation must not fabricate one.
class SmsMessage {
  const SmsMessage({
    required this.sender,
    required this.body,
    required this.receivedAt,
  });

  final String? sender;
  final String body;
  final DateTime receivedAt;
}
