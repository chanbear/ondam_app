-- users: per-elder profile row, sketched in technical-decisions.md §4
-- ("id, phone, name, age, region, easy_mode_enabled") but never created
-- until a Phase actually needed one of those fields. ONDAM 2.0 Phase 25
-- (요구사항 31/32 — 내 지역 입력/현재 위치 자동입력) is that Phase, and only
-- needs the region columns — name/age/easy_mode_enabled stay out of this
-- migration until a later Phase actually implements saving them (profile_page
-- 의 이름/나이 입력은 여전히 UI만 존재, "저장 준비 중" 안내만 한다).
--
-- Region is deliberately split into 3 columns (시/도, 시/군/구, 읍/면/동)
-- instead of one free-text string, so `welfare_center`'s future location
-- search can filter/join on a specific tier instead of parsing a blob
-- (요구사항 31 §3 "지역 문자열 하나를 아무렇게나 저장하는 방식으로 끝내지
-- 않는다").
--
-- `id` doubles as the FK to `auth.users` (1:1 row per user, same pattern as
-- `pin_credentials`) rather than a separate surrogate key + `user_id`
-- column — there is never more than one profile row per user.

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  region_sido text,
  region_sigungu text,
  region_dong text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.users is
  'Per-elder profile row (technical-decisions.md §4). Only region_* columns are populated as of ONDAM 2.0 Phase 25 — name/age/easy_mode_enabled are reserved for when a later Phase actually implements saving them.';

alter table public.users enable row level security;

-- A user may read/write only their own row — same shape as
-- fcm_tokens_select_own/insert_own/update_own (20260814000003), except this
-- table's PK IS the user id, so the check is against `id` directly.
create policy "users_select_own"
  on public.users
  for select
  to authenticated
  using (id = auth.uid());

create policy "users_insert_own"
  on public.users
  for insert
  to authenticated
  with check (id = auth.uid());

create policy "users_update_own"
  on public.users
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Deliberately no delete policy — same reasoning as fcm_tokens (account
-- deletion, if ever exposed, is a separate administrative/Edge Function
-- concern, not a plain client DELETE).
