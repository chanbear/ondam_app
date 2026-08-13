import { createClient } from "jsr:@supabase/supabase-js@2";

// Two-client pattern used by every PIN-related Edge Function:
//
// 1. An anon-key client scoped to the caller's own `Authorization: Bearer
//    <JWT>` header, used ONLY to ask Supabase Auth "who is this token
//    really for" via `.auth.getUser()`. This is the identity check.
// 2. A service-role client, used to make the actual privileged RPC call
//    (`set_pin`/`verify_pin`, whose EXECUTE is granted to `service_role`
//    only) with the verified user id passed explicitly as `p_user_id`.
//
// This split exists because `set_pin`/`verify_pin` cannot rely on
// `auth.uid()` internally — they run under the service role, which carries
// no end-user JWT context, so `auth.uid()` would be NULL inside them. The
// identity check has to happen here, in the Edge Function, before the
// privileged call is made. See supabase/migrations/20260812000003_pin_functions.sql.
export type VerifiedCaller = {
  userId: string;
  /** ISO timestamp of the caller's most recent sign-in, per Supabase Auth. */
  lastSignInAt: string | null;
  serviceClient: ReturnType<typeof createClient>;
};

export type VerifyCallerError = {
  error: "missing_authorization" | "invalid_session";
};

export async function verifyCaller(
  req: Request,
): Promise<VerifiedCaller | VerifyCallerError> {
  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return { error: "missing_authorization" };
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });

  const { data, error } = await callerClient.auth.getUser();
  if (error || !data.user) {
    return { error: "invalid_session" };
  }

  // Separate client: the service role key must never be attached to a
  // client that also carries the caller's JWT, and it is never sent back
  // to the client in any response.
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  return {
    userId: data.user.id,
    lastSignInAt: data.user.last_sign_in_at ?? null,
    serviceClient,
  };
}
