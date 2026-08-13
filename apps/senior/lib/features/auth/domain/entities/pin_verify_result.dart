/// Why a PIN check did not succeed. Mirrors the `reason` field returned by
/// the `verify-pin` Edge Function (supabase/functions/verify-pin/index.ts).
enum PinVerifyFailureReason {
  pinNotSet,
  wrongPin,
  locked,
  invalidFormat,
  unknown,
}

/// Outcome of a PIN verification attempt. `failedAttempts`/`lockedUntil` are
/// server-authoritative counters (technical-decisions.md §1-3-A) — the
/// client never tracks or resets them itself, it only displays them.
class PinVerifyResult {
  const PinVerifyResult.success()
    : ok = true,
      reason = null,
      failedAttempts = null,
      lockedUntil = null;

  const PinVerifyResult.failure({
    required PinVerifyFailureReason this.reason,
    this.failedAttempts,
    this.lockedUntil,
  }) : ok = false;

  final bool ok;
  final PinVerifyFailureReason? reason;
  final int? failedAttempts;
  final DateTime? lockedUntil;
}
