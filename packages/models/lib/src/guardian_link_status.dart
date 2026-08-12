/// Status of a Senior↔Guardian connection request. A link becomes visible to
/// the guardian's "accepted"-scoped queries only once the elder accepts —
/// see technical-decisions.md §1-6.
enum GuardianLinkStatus { pending, accepted, rejected, revoked }
