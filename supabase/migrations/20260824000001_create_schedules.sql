-- schedules: 범용 일정(제목+날짜시간+완료여부) + 복약처럼 "매일 같은
-- 시각 반복"하는 단순 케이스만 지원하는 반복 옵션. Senior 앱의 "기록 탭 -
-- 일정" 섹션과 Guardian 앱의 "다가오는 일정" 섹션이 같은 이 테이블의 서로
-- 다른 뷰다 — analysis_results에서 분리된 독립 도메인으로 취급한다
-- (feature-spec.md MODIFY-9 확정, architecture.md 스케치).
--
-- 컬럼명은 elder_id로 맞췄다(원안은 user_id) — analysis_results/
-- guardian_links 등 "어르신 소유 + 연결된 보호자가 읽는" 다른 모든
-- 테이블이 elder_id를 쓰고 있어, RLS 정책을 그대로 재사용하려면 같은
-- 이름이어야 자연스럽다.

create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  elder_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  scheduled_at timestamptz not null,
  is_recurring boolean not null default false,
  -- 복약처럼 매일 같은 시각 반복하는 단순 케이스만 지원(RRULE 같은 복잡한
  -- 반복 규칙은 요구사항에 없음) — is_recurring=true일 때만 값이 있고,
  -- 항상 scheduled_at의 시:분과 같은 값이다(폼에서 시각을 두 번 묻지
  -- 않는다). 애플리케이션 레벨 불변식이라 DB에서 CHECK로 강제하지 않는다
  -- (users.age가 범위 검증을 도메인에 맡기는 것과 동일한 판단).
  recurrence_time time,
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.schedules is
  '어르신 일정(범용 + 단순 매일 반복). Senior "기록 탭 - 일정"과 Guardian "다가오는 일정"이 공유하는 원천 데이터(feature-spec.md MODIFY-9). updated_at은 트리거가 아니라 앱이 update 시 직접 채운다(profile_remote_datasource.dart와 동일한 기존 패턴).';

create index if not exists schedules_elder_id_scheduled_at_idx
  on public.schedules (elder_id, scheduled_at);

alter table public.schedules enable row level security;

-- (a) 어르신 본인 — 전체 CRUD.
create policy "schedules_select_elder"
  on public.schedules
  for select
  to authenticated
  using (elder_id = auth.uid());

create policy "schedules_insert_elder"
  on public.schedules
  for insert
  to authenticated
  with check (elder_id = auth.uid());

create policy "schedules_update_elder"
  on public.schedules
  for update
  to authenticated
  using (elder_id = auth.uid())
  with check (elder_id = auth.uid());

create policy "schedules_delete_elder"
  on public.schedules
  for delete
  to authenticated
  using (elder_id = auth.uid());

-- (b) accepted 상태로 연결된 보호자 — 읽기 전용(analysis_results의
-- analysis_results_select_accepted_guardian과 동일한 패턴, 20260814000001
-- 참고). pending/rejected/revoked는 접근 불가.
create policy "schedules_select_accepted_guardian"
  on public.schedules
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
