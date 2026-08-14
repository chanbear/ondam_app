-- Phase 8 hardening: fixes two silent-failure gaps found during Backend/
-- Guardian integration validation.
--
-- 1) notifications.read_at: the table is select-only RLS (20260814000002) by
--    design — no client UPDATE policy exists. Guardian's original
--    client-side `.update({read_at: ...})` therefore matched 0 rows under
--    RLS, and PostgREST returns that as a normal (non-error) empty
--    response — so the app reported success while nothing was written. Fix:
--    a narrow SECURITY DEFINER RPC that only ever touches `read_at` on the
--    caller's own notification. This does NOT open a general UPDATE policy
--    on the table — every other column stays client-immutable.
--
-- 2) fcm_tokens: no DELETE policy exists (20260814000003, documented there
--    as a known gap). Guardian's `deleteToken()` on logout matched 0 rows
--    under RLS for the same silent-success reason. Fix: an owner-only
--    DELETE policy, matching the table's existing owner-only
--    select/insert/update policies.

-- ---------------------------------------------------------------------------
-- 1) mark_notification_read RPC
-- ---------------------------------------------------------------------------
-- Deliberately does NOT take a p_user_id parameter the way
-- set_pin/verify_pin/create_connection_token do (20260812000003,
-- 20260813000002) — those trust an Edge-Function-verified p_user_id because
-- service_role calls carry no end-user JWT (auth.uid() would be null there).
-- This function is the opposite case: it IS called directly by the
-- authenticated Flutter client with the caller's own session, so auth.uid()
-- is exactly the right, unspoofable identity source — ownership is checked
-- against it directly instead of trusting a client-supplied id.
create or replace function public.mark_notification_read(p_notification_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_updated integer;
begin
  update public.notifications
  set read_at = coalesce(read_at, now())
  where id = p_notification_id
    and target_user_id = auth.uid();

  get diagnostics v_updated = row_count;
  return v_updated > 0;
end;
$$;

comment on function public.mark_notification_read(uuid) is
  'Sets read_at on the caller''s own notification only (target_user_id = auth.uid()). Returns true iff a row was found and owned by the caller (idempotent — an already-read row still returns true and is left unchanged via coalesce). Returns false for not-found or not-owned, indistinguishably, so a caller cannot use the return value to probe whether some other user''s notification id exists. This is the only path that can ever write read_at — notifications has no client UPDATE RLS policy (20260814000002) and this function intentionally does not open one.';

revoke all on function public.mark_notification_read(uuid) from public, anon;
grant execute on function public.mark_notification_read(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2) fcm_tokens: owner-only DELETE policy (closes the gap noted in
--    20260814000003's header comment)
-- ---------------------------------------------------------------------------
create policy "fcm_tokens_delete_own"
  on public.fcm_tokens
  for delete
  to authenticated
  using (user_id = auth.uid());
