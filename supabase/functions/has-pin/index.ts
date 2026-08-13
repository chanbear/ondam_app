import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// Router-support endpoint only: "does this signed-in user have a PIN yet".
// Used to decide PIN-setup vs PIN-entry after a session exists — never
// exposes anything about the PIN itself (see has_pin() in
// 20260812000003_pin_functions.sql).
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

  const { data, error } = await caller.serviceClient.rpc("has_pin", {
    p_user_id: caller.userId,
  });

  if (error) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  return json({ ok: true, hasPin: Boolean(data) });
});
