-- QR-based connection token issuance/redemption, as SECURITY DEFINER
-- functions — same pattern and checklist as
-- 20260812000003_pin_functions.sql (see that file's header comment for the
-- full 7-point checklist this follows: search_path pinned, non-shadowing
-- names, EXECUTE revoked from PUBLIC/authenticated/anon and granted only to
-- service_role, caller identity verified in the Edge Function before the
-- call — never trusted via auth.uid() here).
--
-- technical-decisions.md §1-6 (v9): a QR code carries only this opaque
-- token, never PII. Scanning it is a request to create a pending
-- guardian_links row, not a connection by itself — accept/reject stays a
-- separate, elder-only step gated by RLS (see
-- 20260813000003_guardian_links_write_policies.sql).

create or replace function public.create_connection_token(p_elder_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_token text;
  v_expires_at timestamptz;
begin
  v_token := encode(extensions.gen_random_bytes(24), 'hex');
  v_expires_at := now() + interval '5 minutes';

  insert into public.connection_tokens (token, elder_id, expires_at)
  values (v_token, p_elder_id, v_expires_at);

  return jsonb_build_object('token', v_token, 'expires_at', v_expires_at);
end;
$$;

revoke all on function public.create_connection_token(uuid) from public, authenticated, anon;
grant execute on function public.create_connection_token(uuid) to service_role;


create or replace function public.redeem_connection_token(p_guardian_id uuid, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_record public.connection_tokens%rowtype;
  v_link_id uuid;
  v_status text;
begin
  select * into v_record from public.connection_tokens where token = p_token;

  if not found then
    return jsonb_build_object('ok', false, 'reason', 'invalid_token');
  end if;

  if v_record.used_at is not null then
    return jsonb_build_object('ok', false, 'reason', 'token_already_used');
  end if;

  if v_record.expires_at < now() then
    return jsonb_build_object('ok', false, 'reason', 'token_expired');
  end if;

  if v_record.elder_id = p_guardian_id then
    return jsonb_build_object('ok', false, 'reason', 'self_link_not_allowed');
  end if;

  update public.connection_tokens set used_at = now() where token = p_token;

  -- Re-scanning a still-valid token while already pending/accepted is a
  -- harmless no-op; re-scanning after a rejection/revocation re-opens the
  -- link as a fresh pending request rather than leaving it permanently
  -- stuck (elder_id/guardian_id pair is unique, so this must be an upsert).
  insert into public.guardian_links (elder_id, guardian_id, status)
  values (v_record.elder_id, p_guardian_id, 'pending')
  on conflict (elder_id, guardian_id) do update
    set status = case
      when public.guardian_links.status in ('rejected', 'revoked') then 'pending'
      else public.guardian_links.status
    end,
    responded_at = case
      when public.guardian_links.status in ('rejected', 'revoked') then null
      else public.guardian_links.responded_at
    end
  returning id, status into v_link_id, v_status;

  return jsonb_build_object('ok', true, 'link_id', v_link_id, 'status', v_status);
end;
$$;

revoke all on function public.redeem_connection_token(uuid, text) from public, authenticated, anon;
grant execute on function public.redeem_connection_token(uuid, text) to service_role;
