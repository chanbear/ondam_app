import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Replaces Supabase Phone OTP (requires a paid SMS provider that was never
// configured on this project — signInWithOtp failed with "Unsupported
// phone provider" during real-device testing) with phone-number-only
// signup/login: the caller never proves phone ownership. Product decision
// (2026-08-16, see technical-decisions.md §1-3-A "OTP 제거") accepted that
// tradeoff instead of setting up Twilio.
//
// Supabase Auth cannot issue a phone-based session without OTP through its
// public client APIs, so this function creates (first time) or finds
// (repeat) the auth user via a per-phone password derived deterministically
// from PHONE_SIGNUP_SECRET (HMAC-SHA256) — known only server-side, never
// returned to the client or logged — and signs in with it via the password
// grant. Only the resulting refresh token goes back to the client; it calls
// `supabase.auth.setSession(refreshToken)` to establish the real session.

const encoder = new TextEncoder();

async function derivePassword(phone: string): Promise<string> {
  const secret = Deno.env.get("PHONE_SIGNUP_SECRET")!;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(phone),
  );
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, reason: "method_not_allowed" }, 405);
  }

  const body = await req.json().catch(() => null);
  const phone = body?.phone;
  const name = body?.name;
  if (typeof phone !== "string" || !/^\+[1-9]\d{6,14}$/.test(phone)) {
    return json({ ok: false, reason: "invalid_phone_format" }, 400);
  }
  if (typeof name !== "string" || name.trim().length === 0) {
    return json({ ok: false, reason: "invalid_name" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const password = await derivePassword(phone);

  const anonClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
  });

  let session = await anonClient.auth.signInWithPassword({ phone, password });

  if (session.error) {
    // No existing user for this phone yet — create one, pre-confirmed
    // (deliberately skipping OTP per the product decision above), then
    // sign in the same way.
    const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const { error: createError } = await serviceClient.auth.admin.createUser({
      phone,
      password,
      phone_confirm: true,
      user_metadata: { name: name.trim() },
    });
    if (createError) {
      return json({ ok: false, reason: "server_error" }, 500);
    }
    session = await anonClient.auth.signInWithPassword({ phone, password });
  }

  if (session.error || !session.data.session) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  return json({
    ok: true,
    refreshToken: session.data.session.refresh_token,
  });
});
