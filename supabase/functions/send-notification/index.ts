import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// Thin notification dispatch: creates a `notifications` row (the durable
// "was this sent" record) and best-effort forwards it to FCM. Per
// technical-decisions.md §1-10, real FCM send logic (server key) must never
// live on the client — this Edge Function is that sole server-side sender.
//
// There is no automatic trigger yet (no risky-message-detection event
// exists in this codebase to trigger from — Phase 7's message_check always
// returns UnavailableFailure for the AI analysis itself). This function is
// therefore invoked directly by an authenticated caller who already knows
// the target user and payload, as instructed. It is NOT unauthenticated or
// unrestricted, though: a caller may only target a user they are linked to
// via an `accepted` guardian_links row (either direction). Without that
// check, any authenticated app user could spam/harass an arbitrary
// target_user_id by id alone — the same access boundary already enforced
// by RLS on analysis_results (20260814000001) is enforced here at the
// application layer, since notifications' own RLS is select-only and this
// function writes via service_role (which bypasses RLS entirely).
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
  const targetUserId = body?.targetUserId;
  const type = body?.type;
  const payload = body?.payload ?? null;
  const sentVia = body?.sentVia ?? "push";

  // Strict UUID format check is required (not just non-empty) because
  // targetUserId is interpolated into a raw PostgREST `.or()` filter string
  // below — an unvalidated value could otherwise inject extra filter
  // clauses (e.g. commas/parentheses) and manipulate the guardian_links
  // authorization check itself.
  const uuidPattern =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (typeof targetUserId !== "string" || !uuidPattern.test(targetUserId)) {
    return json({ ok: false, reason: "invalid_target_user_id" }, 400);
  }
  if (typeof type !== "string" || type.length === 0) {
    return json({ ok: false, reason: "invalid_type" }, 400);
  }
  if (sentVia !== "push" && sentVia !== "sms") {
    return json({ ok: false, reason: "invalid_sent_via" }, 400);
  }
  if (payload !== null && typeof payload !== "object") {
    return json({ ok: false, reason: "invalid_payload" }, 400);
  }

  // Authorization: caller and target must have an accepted guardian_links
  // row, in either direction (see header comment).
  const { data: link, error: linkError } = await caller.serviceClient
    .from("guardian_links")
    .select("id")
    .eq("status", "accepted")
    .or(
      `and(elder_id.eq.${caller.userId},guardian_id.eq.${targetUserId}),and(elder_id.eq.${targetUserId},guardian_id.eq.${caller.userId})`,
    )
    .limit(1)
    .maybeSingle();

  if (linkError) {
    return json({ ok: false, reason: "server_error" }, 500);
  }
  if (!link) {
    return json({ ok: false, reason: "not_linked" }, 403);
  }

  const { data: inserted, error: insertError } = await caller.serviceClient
    .from("notifications")
    .insert({
      target_user_id: targetUserId,
      type,
      payload,
      sent_via: sentVia,
    })
    .select("id, created_at")
    .single();

  if (insertError || !inserted) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  if (sentVia !== "push") {
    // SMS channel is structurally allowed (§1-4 채널 확장 구조) but has no
    // implementation yet — see OPEN QUESTIONS #3. Do not fabricate a send.
    return json({
      ok: true,
      notificationId: inserted.id,
      pushSent: false,
      reason: "channel_not_implemented",
    });
  }

  const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmServerKey) {
    // No Firebase project/server key configured in this environment.
    // The notification row above still exists (source of truth for the
    // Guardian app's in-app notification list) — this only means the push
    // itself was not attempted. Callers must not interpret `ok: true` here
    // as "push delivered".
    return json({
      ok: true,
      notificationId: inserted.id,
      pushSent: false,
      reason: "fcm_not_configured",
    });
  }

  const { data: tokenRows, error: tokenError } = await caller.serviceClient
    .from("fcm_tokens")
    .select("token")
    .eq("user_id", targetUserId);

  if (tokenError) {
    return json({
      ok: true,
      notificationId: inserted.id,
      pushSent: false,
      reason: "token_lookup_failed",
    });
  }

  const tokens = (tokenRows ?? []).map((row) => row.token as string);
  if (tokens.length === 0) {
    return json({
      ok: true,
      notificationId: inserted.id,
      pushSent: false,
      reason: "no_registered_device",
    });
  }

  // FCM legacy HTTP API (server-key based), matching technical-decisions.md
  // §1-10's "서버 키 사용" wording. Google has deprecated this endpoint in
  // favor of the HTTP v1 API (OAuth service-account based) — migrating is a
  // known follow-up once a real Firebase project is actually wired in (see
  // report), not done here since it cannot be exercised in this
  // environment either way.
  //
  // `elder_id`/`analysis_result_id` are forwarded from `payload` into the
  // FCM `data` block (not just stored in `notifications.payload`) because
  // Guardian's push-tap deep link reads them directly off the received
  // `RemoteMessage.data` — see apps/guardian/lib/features/notification/
  // domain/entities/notification_item.dart's doc comment and
  // presentation/services/notification_navigation.dart's
  // `resolveAndNavigateToAnalysisDetail`. Without this, tapping an actual
  // push notification (as opposed to an in-app list row, which reads
  // `notifications.payload` instead) silently did nothing — found and
  // fixed during Phase 8 E2E validation.
  const fcmData: Record<string, string> = { type, notificationId: inserted.id };
  if (payload && typeof payload === "object") {
    const p = payload as Record<string, unknown>;
    if (typeof p.elder_id === "string") fcmData.elder_id = p.elder_id;
    if (typeof p.analysis_result_id === "string") {
      fcmData.analysis_result_id = p.analysis_result_id;
    }
  }

  const sendResults = await Promise.all(
    tokens.map(async (token) => {
      try {
        const res = await fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            Authorization: `key=${fcmServerKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title: typeof payload?.title === "string" ? payload.title : type,
              body: typeof payload?.body === "string" ? payload.body : "",
            },
            data: fcmData,
          }),
        });
        return res.ok;
      } catch {
        return false;
      }
    }),
  );

  const successCount = sendResults.filter(Boolean).length;

  return json({
    ok: true,
    notificationId: inserted.id,
    pushSent: successCount > 0,
    sentCount: successCount,
    totalTokens: tokens.length,
  });
});
