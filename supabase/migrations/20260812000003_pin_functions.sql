-- PIN hashing/verification, implemented as SECURITY DEFINER functions using
-- pgcrypto (bcrypt) instead of Argon2id in a Deno Edge Function — see
-- docs/architecture/technical-decisions.md §1-3-A "PIN 해시 알고리즘 기술
-- 검증" for why (Supabase Edge Function 2s CPU budget + immature Deno
-- Argon2 WASM libraries made Argon2id-in-Deno too risky to commit to).
--
-- SECURITY DEFINER checklist (per this project's Phase 2 requirements —
-- do not add a function here without re-checking every point):
--   1. `set search_path = public, pg_temp` on every function below, so a
--      caller cannot shadow pgcrypto/table lookups by manipulating search_path.
--   2. Functions live in `public` schema under names that do not shadow any
--      extension-provided function (`set_pin`/`verify_pin` are project-specific
--      names, not pgcrypto/auth built-ins).
--   3. EXECUTE is revoked from PUBLIC/authenticated/anon explicitly below.
--   4. EXECUTE is granted ONLY to `service_role`.
--   5+6. Caller identity is NOT taken from `auth.uid()` inside these
--      functions, because they are invoked by the Edge Function using the
--      SERVICE ROLE client (where auth.uid() would be NULL — service role
--      calls carry no end-user JWT context). Instead, the Edge Function
--      independently verifies the caller's JWT first (via
--      supabase/functions/_shared/auth.ts) and passes the verified
--      `p_user_id` explicitly. Because EXECUTE is service_role-only, a
--      client cannot call these functions directly to pass an arbitrary
--      `p_user_id` and probe another user's PIN — only our own Edge
--      Functions (which already verified identity) can reach them at all.
--   7. The service_role key itself is never sent to the Flutter client —
--      it exists only as an Edge Function secret (see supabase/functions/_shared/auth.ts).

create or replace function public.set_pin(p_user_id uuid, p_pin text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_pin !~ '^[0-9]{4}$' then
    raise exception 'PIN must be exactly 4 digits' using errcode = '22023';
  end if;

  insert into public.pin_credentials (user_id, pin_hash, failed_attempts, locked_until, updated_at)
  values (p_user_id, extensions.crypt(p_pin, extensions.gen_salt('bf')), 0, null, now())
  on conflict (user_id) do update
    set pin_hash = excluded.pin_hash,
        failed_attempts = 0,
        locked_until = null,
        updated_at = now();
end;
$$;

revoke all on function public.set_pin(uuid, text) from public, authenticated, anon;
grant execute on function public.set_pin(uuid, text) to service_role;


create or replace function public.verify_pin(p_user_id uuid, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_record public.pin_credentials%rowtype;
  v_ok boolean;
  v_new_attempts integer;
  v_lock_minutes integer;
begin
  select * into v_record from public.pin_credentials where user_id = p_user_id;
  if not found then
    return jsonb_build_object('ok', false, 'reason', 'pin_not_set');
  end if;

  if v_record.locked_until is not null and v_record.locked_until > now() then
    return jsonb_build_object(
      'ok', false,
      'reason', 'locked',
      'locked_until', v_record.locked_until
    );
  end if;

  v_ok := (extensions.crypt(p_pin, v_record.pin_hash) = v_record.pin_hash);

  if v_ok then
    update public.pin_credentials
      set failed_attempts = 0, locked_until = null, updated_at = now()
      where user_id = p_user_id;
    return jsonb_build_object('ok', true);
  end if;

  -- Lockout policy (technical-decisions.md §1-3-A "PIN 정책 확정값"):
  -- 5 consecutive failures -> 5 min lock, cumulative 10 -> 30 min lock,
  -- every 5 beyond that doubles the lock duration, capped at 24h.
  v_new_attempts := v_record.failed_attempts + 1;
  v_lock_minutes := case
    when v_new_attempts < 5 then 0
    when v_new_attempts < 10 then 5
    else least(1440, (30 * power(2, ((v_new_attempts - 10) / 5)))::integer)
  end;

  update public.pin_credentials
    set failed_attempts = v_new_attempts,
        locked_until = case
          when v_lock_minutes > 0 then now() + (v_lock_minutes || ' minutes')::interval
          else locked_until
        end,
        updated_at = now()
    where user_id = p_user_id;

  return jsonb_build_object(
    'ok', false,
    'reason', 'wrong_pin',
    'failed_attempts', v_new_attempts
  );
end;
$$;

revoke all on function public.verify_pin(uuid, text) from public, authenticated, anon;
grant execute on function public.verify_pin(uuid, text) to service_role;

-- Router-support function: lets the client learn "has this signed-in user
-- already set a PIN" (to route to PIN entry) vs "not yet" (to route to PIN
-- setup) WITHOUT ever granting read access to pin_credentials itself. Only
-- a boolean crosses the boundary — no hash, no attempt counters.
create or replace function public.has_pin(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.pin_credentials where user_id = p_user_id);
$$;

revoke all on function public.has_pin(uuid) from public, authenticated, anon;
grant execute on function public.has_pin(uuid) to service_role;

-- PIN reset (forgot PIN, after fresh OTP re-verification) intentionally
-- reuses set_pin rather than duplicating the upsert logic — resetting is
-- semantically "set a new PIN", the only difference is what the client did
-- right before calling it (OTP re-auth instead of first-time signup). The
-- reset-pin Edge Function additionally checks session freshness before
-- calling this same RPC — see supabase/functions/reset-pin/index.ts.
