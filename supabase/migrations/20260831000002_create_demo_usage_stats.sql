-- DEMO 계정 전용 "몇 개월째 이용 중" 표시값. QR 연결(guardian_links)이
-- accepted로 바뀌는 순간 딱 한 번 자동으로 채워지는, 실제 AI 분석과 무관한
-- 장식용 요약이다. `analysis_results`(실제 분석 이력)는 이 migration이
-- 전혀 건드리지 않는다 — service_role만 쓸 수 있고 client insert 정책이
-- 없는 그 설계를 그대로 존중한다. Guardian 화면은 이 테이블의 값을 반드시
-- "데모" 표시와 함께 보여줘야 하고, 실제 분석 기록 목록(analysis_results
-- 기반)에는 이 값을 절대 섞지 않는다.

create table if not exists public.demo_usage_stats (
  elder_id uuid primary key references auth.users (id) on delete cascade,
  since timestamptz not null,
  analysis_count integer not null,
  created_at timestamptz not null default now()
);

comment on table public.demo_usage_stats is
  'Cosmetic-only "used for N months" figure seeded once a QR connection is accepted. Not derived from and never mixed into analysis_results — Guardian UI must always pair it with a visible "데모" label so it is never mistaken for real analysis history.';

create index if not exists demo_usage_stats_elder_id_idx
  on public.demo_usage_stats (elder_id);

alter table public.demo_usage_stats enable row level security;

-- Only the guardian side of an accepted link needs this (it exists purely
-- to decorate the Guardian home card) — no elder-facing use case today, so
-- no elder select policy (YAGNI).
create policy "demo_usage_stats_select_accepted_guardian"
  on public.demo_usage_stats
  for select
  to authenticated
  using (
    elder_id in (
      select elder_id
      from public.guardian_links
      where guardian_id = auth.uid()
        and status = 'accepted'
    )
  );

-- Deliberately no insert/update/delete policy for any client role — the
-- trigger below (SECURITY DEFINER) is the only writer, same pattern as
-- redeem_connection_token (20260813000002_connection_functions.sql).
create or replace function public.seed_demo_usage_stats()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.demo_usage_stats (elder_id, since, analysis_count)
  values (
    new.elder_id,
    now() - (floor(random() * 4 + 3)::int || ' months')::interval,
    floor(random() * 30 + 10)::int
  )
  on conflict (elder_id) do nothing;
  return new;
end;
$$;

comment on function public.seed_demo_usage_stats() is
  'Fires once per elder when a guardian_links row first transitions to accepted (covers both the direct-RLS-update accept path and any future edge function that performs the same UPDATE — single choke point). Values are randomized placeholders, not real usage.';

drop trigger if exists guardian_links_seed_demo_usage_stats on public.guardian_links;

create trigger guardian_links_seed_demo_usage_stats
  after update on public.guardian_links
  for each row
  when (new.status = 'accepted' and old.status is distinct from 'accepted')
  execute function public.seed_demo_usage_stats();
