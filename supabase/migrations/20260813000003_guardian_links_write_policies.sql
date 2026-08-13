-- guardian_links INSERT/UPDATE policies — the piece 20260812000004 explicitly
-- deferred to "the connection feature's own migration in Phase 5". This is
-- that migration (technical-decisions.md §1-6 v9, QR-based flow).
--
-- INSERT: intentionally still no client-facing policy. A pending row is only
-- ever created by redeem_connection_token() (20260813000002), which runs as
-- service_role and therefore bypasses RLS entirely — a client can never
-- INSERT into guardian_links directly, QR token or not.
--
-- UPDATE: both parties may reach the row (RLS below), but WHICH transition
-- each may perform is enforced per-actor inside the trigger, not by RLS
-- alone — a plain `using`/`with check` can restrict WHO can touch a row,
-- but not "only the elder may do THIS transition, either party may do
-- THAT one" in a single policy without duplicating rows across multiple
-- policies. Concretely:
--   - pending -> accepted/rejected: elder only (technical-decisions.md §2
--     item 3: "보호자가 status='accepted'를 직접 쓰는 것은 금지").
--   - accepted -> revoked: either party (§1-5 필수요구사항 2 gives the
--     elder revoke; the old app's "연결 해제" was guardian-only — the new
--     app keeps that as well, not removes it — so both may end an accepted
--     connection).
-- `auth.uid()` still resolves to the real calling user inside a SECURITY
-- DEFINER trigger (it reads the request's JWT claims via PostgREST's
-- session config, unaffected by the function owner), so this check is safe
-- to do here even though the function itself runs with elevated privilege.

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
  elsif old.status = 'accepted' and new.status = 'revoked' then
    if auth.uid() <> old.elder_id and auth.uid() <> old.guardian_id then
      raise exception 'guardian_links: 연결 해제 권한이 없습니다' using errcode = '42501';
    end if;
  else
    raise exception 'guardian_links: 허용되지 않는 상태 전이입니다 (% -> %)', old.status, new.status
      using errcode = '22023';
  end if;

  new.responded_at := now();
  return new;
end;
$$;

drop trigger if exists guardian_links_validate_update on public.guardian_links;
create trigger guardian_links_validate_update
  before update on public.guardian_links
  for each row
  execute function public.guardian_links_validate_update();

create policy "guardian_links_update_party"
  on public.guardian_links
  for update
  to authenticated
  using (elder_id = auth.uid() or guardian_id = auth.uid())
  with check (elder_id = auth.uid() or guardian_id = auth.uid());
