/// A short-lived, single-use token issued by the server so this device can
/// render it as a QR code for a guardian to scan (technical-decisions.md
/// §1-6 v9). Pure Dart — no rendering concerns here.
class ConnectionToken {
  const ConnectionToken({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
