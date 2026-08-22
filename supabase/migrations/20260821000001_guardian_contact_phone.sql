-- get_connected_guardian_phone: exposes the phone number of an elder's
-- connected guardian, for the Senior app's 긴급 도움(emergency help) sheet
-- to actually dial (previously a permanent placeholder — see
-- technical-decisions.md v15 — because no path to a guardian's phone
-- existed at all: guardian_links only stores guardian_id, and auth.users
-- (where phone actually lives, set at signup-with-phone) has no
-- client-facing SELECT policy). SECURITY DEFINER is the only way to read
-- auth.users here, same pattern as guardian_links_validate_update
-- (20260813000003) and mark_notification_read (20260814000004) — scoped to
-- auth.uid() so an elder can only ever resolve their own guardian's phone.
--
-- Returns the earliest-accepted guardian's phone if the elder has more than
-- one connection — this app has no "primary guardian" concept yet
-- (technical-decisions.md doesn't define one), so oldest-accepted is the
-- least arbitrary tiebreak available. Returns null (not an error) when the
-- elder has no accepted guardian connection.
create or replace function public.get_connected_guardian_phone()
returns text
language sql
security definer
set search_path = public, pg_temp
stable
as $$
  select u.phone
  from public.guardian_links gl
  join auth.users u on u.id = gl.guardian_id
  where gl.elder_id = auth.uid()
    and gl.status = 'accepted'
  order by gl.responded_at asc nulls last, gl.created_at asc
  limit 1
$$;

comment on function public.get_connected_guardian_phone() is
  'Returns the phone number of the calling elder''s earliest-accepted guardian, or null if none. SECURITY DEFINER so it can read auth.users, which has no client-facing SELECT policy; scoped to auth.uid() = elder_id so a user can never read another elder''s guardian phone.';

revoke all on function public.get_connected_guardian_phone() from public, anon;
grant execute on function public.get_connected_guardian_phone() to authenticated;
