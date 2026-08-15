import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";

// FCM HTTP v1 (OAuth 2.0 service-account) transport ------------------------
// Replaces the deprecated Legacy FCM HTTP API (`FCM_SERVER_KEY`, "key=" auth
// header) that this function used before. The service-account credential is
// stored as ONE secret (`FIREBASE_SERVICE_ACCOUNT_JSON`, exactly the JSON
// file Firebase Console → Project Settings → Service Accounts → Generate new
// private key gives you) rather than split into
// FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY secrets —
// splitting would not reduce the one real operational risk here (the
// multi-line PEM `private_key`'s embedded newlines getting corrupted when
// pasted as a bare secret value) and would only add two more secret-name
// typo failure points. A JSON blob already escapes those newlines as `\n`
// inside a string, so it survives being pasted as a single secret value and
// `JSON.parse` restores real newlines automatically.
type ServiceAccount = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

function parseServiceAccount(raw: string): ServiceAccount | null {
  try {
    const obj = JSON.parse(raw);
    if (
      typeof obj?.project_id === "string" &&
      typeof obj?.client_email === "string" &&
      typeof obj?.private_key === "string"
    ) {
      return {
        projectId: obj.project_id,
        clientEmail: obj.client_email,
        privateKey: obj.private_key,
      };
    }
    return null;
  } catch {
    return null;
  }
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlEncodeString(s: string): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(s));
}

async function importSigningKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(pemBody);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return await crypto.subtle.importKey(
    "pkcs8",
    bytes.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

// In-memory per-warm-instance cache — avoids re-signing a JWT and round-
// tripping to Google's token endpoint on every invocation. Never logged,
// never returned to any caller; lost on cold start (acceptable, the next
// call just re-mints one).
let cachedAccessToken: { token: string; expiresAt: number } | null = null;

// Exchanges the service account for a short-lived OAuth2 access token via
// the JWT Bearer flow (RFC 7523) — no external OAuth library needed, Deno's
// Web Crypto API covers RS256 signing natively.
async function getAccessToken(
  sa: ServiceAccount,
): Promise<{ ok: true; token: string } | { ok: false; reason: string }> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return { ok: true, token: cachedAccessToken.token };
  }

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64UrlEncodeString(JSON.stringify(header))}.${
    base64UrlEncodeString(JSON.stringify(claims))
  }`;

  let key: CryptoKey;
  try {
    key = await importSigningKey(sa.privateKey);
  } catch (e) {
    // Never log the key material itself — only that parsing failed.
    console.error(
      "send-notification: failed to import service account private key",
      (e as Error)?.name,
    );
    return { ok: false, reason: "invalid_service_account_key" };
  }

  let signature: ArrayBuffer;
  try {
    signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    );
  } catch {
    return { ok: false, reason: "jwt_signing_failed" };
  }

  const assertion = `${unsigned}.${
    base64UrlEncodeBytes(new Uint8Array(signature))
  }`;

  let response: Response;
  try {
    response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    });
  } catch (e) {
    console.error("send-notification: OAuth token fetch threw", e);
    return { ok: false, reason: "oauth_provider_error" };
  }

  if (!response.ok) {
    // Google's error body describes the request problem, never echoes back
    // the key we sent (we sent a signed JWT, not the raw key) — safe to log
    // a truncated snippet, same pattern as analyze-message's Anthropic error
    // logging.
    const errText = await response.text().catch(() => "<unreadable>");
    console.error(
      `send-notification: OAuth token endpoint responded ${response.status}`,
      errText.slice(0, 300),
    );
    return { ok: false, reason: "oauth_token_denied" };
  }

  let tokenBody: { access_token?: string; expires_in?: number };
  try {
    tokenBody = await response.json();
  } catch {
    return { ok: false, reason: "oauth_response_invalid" };
  }

  if (typeof tokenBody.access_token !== "string") {
    return { ok: false, reason: "oauth_response_invalid" };
  }

  const expiresIn = typeof tokenBody.expires_in === "number"
    ? tokenBody.expires_in
    : 3600;
  cachedAccessToken = {
    token: tokenBody.access_token,
    expiresAt: now + expiresIn,
  };
  return { ok: true, token: tokenBody.access_token };
}

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

  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!serviceAccountRaw) {
    // No Firebase service account configured in this environment. The
    // notification row above still exists (source of truth for the
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
  const serviceAccount = parseServiceAccount(serviceAccountRaw);
  if (!serviceAccount) {
    // Never log the raw secret value — only that it failed to parse.
    console.error(
      "send-notification: FIREBASE_SERVICE_ACCOUNT_JSON is not valid service-account JSON",
    );
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

  const accessTokenResult = await getAccessToken(serviceAccount);
  if (!accessTokenResult.ok) {
    // Access-token acquisition failed (bad key, Google outage, etc.) — the
    // notification row still exists; report a specific, honest reason
    // instead of a fabricated push.
    return json({
      ok: true,
      notificationId: inserted.id,
      pushSent: false,
      reason: accessTokenResult.reason,
    });
  }
  const accessToken = accessTokenResult.token;

  // FCM HTTP v1 (OAuth service-account based) — replaces the deprecated
  // Legacy FCM HTTP API this function used before (§1-10 "서버 키 사용" is
  // still satisfied: the credential lives only in this server-side secret).
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
  // fixed during Phase 8 E2E validation. `risk_level`/`risk_type` are NOT
  // forwarded here (only `elder_id`/`analysis_result_id` ever were) — the
  // Guardian client's deep-link reader only consumes those two keys today;
  // this migration preserves that exact existing contract rather than
  // expanding it.
  const fcmData: Record<string, string> = { type, notificationId: inserted.id };
  if (payload && typeof payload === "object") {
    const p = payload as Record<string, unknown>;
    if (typeof p.elder_id === "string") fcmData.elder_id = p.elder_id;
    if (typeof p.analysis_result_id === "string") {
      fcmData.analysis_result_id = p.analysis_result_id;
    }
  }

  const fcmEndpoint =
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.projectId}/messages:send`;

  const sendResults = await Promise.all(
    tokens.map(async (token) => {
      try {
        const res = await fetch(fcmEndpoint, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: typeof payload?.title === "string"
                  ? payload.title
                  : type,
                body: typeof payload?.body === "string" ? payload.body : "",
              },
              data: fcmData,
            },
          }),
        });
        if (!res.ok) {
          // 4xx/5xx from FCM v1 is never treated as success. Body can
          // include a diagnostic (e.g. UNREGISTERED for a stale token) —
          // safe to log, contains no credential material.
          const errText = await res.text().catch(() => "<unreadable>");
          console.error(
            `send-notification: FCM v1 responded ${res.status}`,
            errText.slice(0, 300),
          );
          return false;
        }
        // Success body is `{"name": "projects/.../messages/<id>"}` — just a
        // message id, not sensitive. Log-only for traceability; never
        // returned to the caller (client-facing response shape unchanged).
        try {
          const okBody = await res.json();
          console.log("send-notification: FCM v1 accepted", okBody?.name);
        } catch {
          // 2xx with a non-JSON/unparseable body still counts as sent.
        }
        return true;
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
