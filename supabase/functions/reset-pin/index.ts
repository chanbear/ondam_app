import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// PIN-forgot flow: client re-authenticates via OTP first (a fresh Supabase
// Auth sign-in, not just PIN entry), then calls this function to set a new
// PIN. We never decrypt/recover the old PIN — bcrypt hashes are one-way,
// this is always "overwrite with a new PIN", same RPC as set-pin.
const FRESHNESS_WINDOW_MS = 10 * 60 * 1000; // 10 minutes

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

  // Defense in depth beyond "has a valid session": PIN reset is a sensitive
  // operation, so require the session's most recent sign-in (the OTP
  // re-auth the client just performed) to be recent. An old, merely-still-
  // valid session cannot be used to silently reset the PIN.
  if (!caller.lastSignInAt) {
    return json({ ok: false, reason: "reauthentication_required" }, 401);
  }
  const signedInAgoMs = Date.now() - new Date(caller.lastSignInAt).getTime();
  if (signedInAgoMs > FRESHNESS_WINDOW_MS) {
    return json({ ok: false, reason: "reauthentication_required" }, 401);
  }

  const body = await req.json().catch(() => null);
  const pin = body?.pin;
  if (typeof pin !== "string" || !/^[0-9]{4}$/.test(pin)) {
    return json({ ok: false, reason: "invalid_pin_format" }, 400);
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
