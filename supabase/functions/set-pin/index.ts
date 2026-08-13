import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// First-time PIN setup, called right after signup once the user has an
// active Supabase session. See technical-decisions.md §1-3-A flow 2.
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

  const { error } = await caller.serviceClient.rpc("set_pin", {
    p_user_id: caller.userId,
    p_pin: pin,
  });

  if (error) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  return json({ ok: true });
});
