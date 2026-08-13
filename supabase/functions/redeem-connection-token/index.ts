import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// Called by the Guardian app right after scanning a Senior's QR code. A
// successful call creates (or re-opens) a `pending` guardian_links row — it
// does NOT complete the connection. Only the elder's explicit accept
// (via direct RLS-gated UPDATE, not this function) does that.
// See technical-decisions.md §1-6 (v9).
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
  const token = body?.token;
  if (typeof token !== "string" || token.length === 0) {
    return json({ ok: false, reason: "invalid_token_format" }, 400);
  }

  const { data, error } = await caller.serviceClient.rpc(
    "redeem_connection_token",
    { p_guardian_id: caller.userId, p_token: token },
  );

  if (error) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  const result = data as {
    ok: boolean;
    reason?: string;
    link_id?: string;
    status?: string;
  };

  if (!result.ok) {
    return json(result, 400);
  }

  return json({ ok: true, linkId: result.link_id, status: result.status });
});
