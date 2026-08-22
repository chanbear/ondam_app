import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// First-time PIN setup, called right after signup once the user has an
// active Supabase session. See technical-decisions.md §1-3-A flow 2.
//
// ONDAM 2.0 Phase 9 security fix: the `set_pin` RPC itself always upserts
// (see 20260812000003_pin_functions.sql's `on conflict (user_id) do
// update`), so without the has_pin check below this endpoint would let
// anyone with *any* valid session — however it was obtained, including via
// `signup-with-phone` (no OTP; phone-number knowledge alone gets a fresh
// session for an *existing* account, technical-decisions.md §1-3-A "OTP
// 제거") — silently overwrite an already-set PIN with zero freshness check
// and independent of lockout state. The Flutter client already only ever
// calls set-pin when `has-pin` returned false (PinSetupPage is unreachable
// once a PIN exists — see auth_redirect.dart's `!hasPin` branch), so this
// server-side check changes nothing for the legitimate flow; it only closes
// the path where a caller skips that client-side gating. Overwriting an
// *existing* PIN must go through reset-pin (which at least requires a
// recent sign-in) instead.
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, reason: "method_not_allowed" }, 405);
  }

  const caller = await verifyCaller(req);
  if ("error" in caller) {
    return json({ ok: false, reason: caller.error }, 401);
  }

  const body = await req.json().catch(() => null);
  const pin = body?.pin;
  if (typeof pin !== "string" || !/^[0-9]{4}$/.test(pin)) {
    return json({ ok: false, reason: "invalid_pin_format" }, 400);
  }

  const { data: alreadyHasPin, error: hasPinError } = await caller
    .serviceClient.rpc("has_pin", { p_user_id: caller.userId });
  if (hasPinError) {
    return json({ ok: false, reason: "server_error" }, 500);
  }
  if (alreadyHasPin) {
    // Not "server_error" — this is a real, expected outcome for a caller
    // that skipped the client's own has-pin gating (or is probing). The
    // client never legitimately hits this: PinSetupPage only renders when
    // has-pin already returned false.
    return json({ ok: false, reason: "pin_already_set" }, 409);
  }

  const { error } = await caller.serviceClient.rpc("set_pin", {
    p_user_id: caller.userId,
    p_pin: pin,
  });

  if (error) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  return json({ ok: true });
});
