/// Status of a Senior↔Guardian connection request. A link becomes visible to
/// the guardian's "accepted"-scoped queries only once the elder accepts —
/// see technical-decisions.md §1-6.
enum GuardianLinkStatus {
  pending,
  accepted,
  rejected,
  revoked;

  /// Matches the `status` text column's
  /// `check (status in ('pending', 'accepted', 'rejected', 'revoked'))`
  /// constraint in `supabase/migrations/20260812000004_create_guardian_links.sql`.
  String toDbValue() => name;

  static GuardianLinkStatus fromDbValue(String value) => switch (value) {
    'pending' => GuardianLinkStatus.pending,
    'accepted' => GuardianLinkStatus.accepted,
    'rejected' => GuardianLinkStatus.rejected,
    'revoked' => GuardianLinkStatus.revoked,
    _ => throw ArgumentError('Unknown guardian_links.status: $value'),
  };
}
