import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// Account deletion relies on `on delete cascade` foreign keys pointing at
// `auth.users(id)` on every table this project currently has
// (`user_roles`, `pin_credentials`, `guardian_links` — see their migration
// files), so deleting the auth user is sufficient today. When later phases
// add new user-owned tables (analysis_results, schedules, notifications,
// fcm_tokens, ...), each of those migrations MUST also declare
// `on delete cascade` against `auth.users(id)` — this function is not the
// place to start hand-listing tables to delete from.
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

  const { error } = await caller.serviceClient.auth.admin.deleteUser(
    caller.userId,
  );

  if (error) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  return json({ ok: true });
});
