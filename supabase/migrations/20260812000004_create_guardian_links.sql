-- guardian_links: Senior<->Guardian connection relationship. Full table per
-- docs/architecture/technical-decisions.md §4 / §1-5 / §1-6.
--
-- Scope note: the `connection` feature (request/accept/reject/revoke flow)
-- is Phase 5, not Phase 2 (Authentication). This migration only creates the
-- table + the constraint Phase 2 explicitly needs (`elder_id <> guardian_id`,
-- technical-decisions.md §2 item "자기 자신을 보호자로 연결하는 어뷰징
-- 방지") plus read-only RLS, so `user_id`-scoped queries elsewhere (e.g.
-- role guidance UX) have a real table to reference. INSERT/UPDATE policies
-- (request creation by guardian, accept/reject/revoke by elder only per
-- §2 item 3: "보호자가 status='accepted'를 직접 쓰는 것은 금지") are left
-- for the connection feature's own migration in Phase 5 — do not add them
-- here.

create table if not exists public.guardian_links (
  id uuid primary key default gen_random_uuid(),
  elder_id uuid not null references auth.users (id) on delete cascade,
  guardian_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'revoked')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint guardian_links_not_self check (elder_id <> guardian_id),
  constraint guardian_links_unique_pair unique (elder_id, guardian_id)
);

comment on table public.guardian_links is
  'Senior<->Guardian connection. elder_id <> guardian_id is enforced at the DB level so a user can never register themselves as their own guardian. Request/accept/reject/revoke write policies belong to the Phase 5 connection feature migration, not here.';

alter table public.guardian_links enable row level security;

-- Both parties to a link may read it. Full detail-field scoping (e.g.
-- guardian only sees elder summary fields once status = 'accepted') is a
-- query/view-level concern for the connection feature, not this RLS policy.
create policy "guardian_links_select_elder"
  on public.guardian_links
  for select
  to authenticated
  using (elder_id = auth.uid());

create policy "guardian_links_select_guardian"
  on public.guardian_links
  for select
  to authenticated
  using (guardian_id = auth.uid());

-- No insert/update/delete policy yet: connection request creation and the
-- accept/reject/revoke transitions are Phase 5 scope.
