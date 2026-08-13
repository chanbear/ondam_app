import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// Everyday app-reentry PIN check. This is the "B안" replacement for asking
// Supabase Auth to re-authenticate on every app open — the Supabase
// Session stays alive per the SDK's normal lifecycle (Session ≠ PIN Gate,
// technical-decisions.md §1-3-A) and this function is the sole gate that
// decides whether the 4-digit PIN the user just typed is correct.
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

  const { data, error } = await caller.serviceClient.rpc("verify_pin", {
    p_user_id: caller.userId,
    p_pin: pin,
  });

  if (error) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  const result = data as {
    ok: boolean;
    reason?: string;
    failed_attempts?: number;
    locked_until?: string;
  };

  if (result.ok) {
    return json(result, 200);
  }

  if (result.reason === "locked") {
    return json(result, 423); // 423 Locked
  }

  // wrong_pin / pin_not_set both map to 401 — the client distinguishes
  // them via `reason`, not via status code, so it can show the right
  // guidance (retry vs "PIN 설정이 필요합니다").
  return json(result, 401);
});
