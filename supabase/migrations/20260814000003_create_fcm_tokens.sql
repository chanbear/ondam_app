-- fcm_tokens: per-device FCM registration token, keyed to the signed-in
-- user (technical-decisions.md §4, §2-5). Column list matches the sketch:
--   id, user_id, token, device_info, updated_at
--
-- Unlike pin_credentials/connection_tokens (service_role-only, no direct
-- client access at all), this table intentionally grants the owning user
-- direct RLS-gated select/insert/update on their own row(s) — the Flutter
-- app's `notification` feature registers/refreshes its own token on
-- startup/token-rotation without needing a dedicated Edge Function for
-- that alone. This still satisfies technical-decisions.md §2-5's "FCM
-- Token 보안" requirement ("토큰-사용자 매핑 테이블에 대한 접근을... 클라
-- 이언트/타 사용자에게 노출하지 않는다") because RLS restricts every client
-- to exactly their own rows — no client can ever read or write another
-- user's token row.
--
-- `token` carries a unique constraint: a physical device/app-install token
-- from FCM is unique by construction, and de-duplicating on it (instead of
-- allowing unbounded rows per user) keeps `send-notification`'s "look up
-- this user's tokens" query from accumulating stale duplicates as a device
-- reinstalls the app or refreshes its token. Reassigning a token's owner
-- (device changed hands) is out of scope here — no client policy allows
-- writing a token row that already belongs to a different user, so that
-- case is left as a known gap for a later Phase (see report).

create table if not exists public.fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  device_info jsonb,
  updated_at timestamptz not null default now(),
  unique (token)
);

comment on table public.fcm_tokens is
  'Per-device FCM registration tokens (technical-decisions.md §4, §2-5). RLS restricts every client to their own user_id rows only. No delete policy yet — token invalidation on logout/device change is not implemented in this Phase (see send-notification report / OPEN QUESTIONS).';

create index if not exists fcm_tokens_user_id_idx
  on public.fcm_tokens (user_id);

alter table public.fcm_tokens enable row level security;

create policy "fcm_tokens_select_own"
  on public.fcm_tokens
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "fcm_tokens_insert_own"
  on public.fcm_tokens
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "fcm_tokens_update_own"
  on public.fcm_tokens
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Deliberately no delete policy — see header comment.
