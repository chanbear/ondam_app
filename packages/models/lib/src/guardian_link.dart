import 'guardian_link_status.dart';

/// Shared shape for a Senior↔Guardian connection — owned by the `connection`
/// feature in both apps. Matches the `guardian_links` table sketched in
/// technical-decisions.md §4.
class GuardianLink {
  const GuardianLink({
    required this.id,
    required this.elderId,
    required this.guardianId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String elderId;
  final String guardianId;
  final GuardianLinkStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
}
