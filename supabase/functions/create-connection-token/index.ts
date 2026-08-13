import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// Called by the Senior app's "보호자 연결" screen to get a short-lived token
// to render as a QR code. See technical-decisions.md §1-6 (v9).
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

  const { data, error } = await caller.serviceClient.rpc(
    "create_connection_token",
    { p_elder_id: caller.userId },
  );

  if (error) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  const result = data as { token: string; expires_at: string };
  return json({ ok: true, token: result.token, expiresAt: result.expires_at });
});
