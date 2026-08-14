-- Fixes a real bug found during Phase 8 REAL E2E validation: a Guardian
-- re-scanning a Senior's QR code after a prior rejection/revocation could
-- never actually reconnect. redeem_connection_token (20260813000002)'s
-- `on conflict (elder_id, guardian_id) do update` intentionally re-opens a
-- 'rejected'/'revoked' row back to 'pending' (see that function's own
-- comment: "재스캔 시... 재오픈") — but ON CONFLICT DO UPDATE fires the
-- table's BEFORE UPDATE trigger, and guardian_links_validate_update
-- (20260813000003) never had a branch for that transition, so it fell
-- through to the catch-all "허용되지 않는 상태 전이입니다" exception,
-- turning every re-connect attempt into a 500 from redeem-connection-token.
--
-- This migration adds that missing branch. No identity check is added for
-- it, for the same reason a brand-new INSERT into 'pending' has never had
-- one: reaching 'pending' has only ever been gated by "did you present a
-- valid, unexpired, unused connection_tokens row" (enforced inside
-- redeem_connection_token itself), not by row-level identity. A client
-- could also reach this same transition via a direct PATCH (allowed by
-- guardian_links_update_party's `elder_id = auth.uid() or guardian_id =
-- auth.uid()`), but 'pending' alone grants no data access — only
-- 'accepted' does, via 20260814000001's guardian_links-gated SELECT
-- policies — so at most this lets a party re-request without a fresh QR
-- token, a UX shortcut, not a privilege escalation.
--
-- Also stops unconditionally stamping `responded_at := now()` for every
-- allowed transition: a reopened 'pending' row should keep responded_at
-- null (a fresh request, not a response-to-date) — the RPC's own
-- `on conflict` SET clause already nulls it; this trigger must not
-- override that back to now() the way it did for every other branch.

create or replace function public.guardian_links_validate_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.id <> old.id
    or new.elder_id <> old.elder_id
    or new.guardian_id <> old.guardian_id
    or new.created_at <> old.created_at then
    raise exception 'guardian_links: id/elder_id/guardian_id/created_at는 변경할 수 없습니다' using errcode = '22023';
  end if;

  if old.status = 'pending' and new.status in ('accepted', 'rejected') then
    if auth.uid() <> old.elder_id then
      raise exception 'guardian_links: 수락/거절은 어르신만 가능합니다' using errcode = '42501';
    end if;
    new.responded_at := now();
  elsif old.status = 'accepted' and new.status = 'revoked' then
    if auth.uid() <> old.elder_id and auth.uid() <> old.guardian_id then
      raise exception 'guardian_links: 연결 해제 권한이 없습니다' using errcode = '42501';
    end if;
    new.responded_at := now();
  elsif old.status in ('rejected', 'revoked') and new.status = 'pending' then
    -- Re-open on re-scan (redeem_connection_token's ON CONFLICT DO
    -- UPDATE) — see header comment for why no identity check is added
    -- here. responded_at is left as whatever the caller set (null).
    null;
  else
    raise exception 'guardian_links: 허용되지 않는 상태 전이입니다 (% -> %)', old.status, new.status
      using errcode = '22023';
  end if;

  return new;
end;
$$;
