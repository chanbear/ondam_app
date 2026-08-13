-- user_roles: the single source of truth for "who is an elder / who is a
-- guardian" — never inferred from which app (Senior/Guardian) a request
-- came from. See docs/architecture/technical-decisions.md §1-3-A "Role 관리".
--
-- One phone number (one auth.users row) may hold both roles at once
-- (decision B, technical-decisions.md OPEN QUESTIONS 15 — DECIDED).

create table if not exists public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('elder', 'guardian')),
  created_at timestamptz not null default now(),
  unique (user_id, role)
);

comment on table public.user_roles is
  'Source of truth for elder/guardian role membership. Never trust the requesting app name for authorization — always check this table.';

alter table public.user_roles enable row level security;

-- A user may read only their own role rows.
create policy "user_roles_select_own"
  on public.user_roles
  for select
  to authenticated
  using (user_id = auth.uid());

-- A user may add a role to themselves only (onboarding "I am an elder / I
-- am a guardian" choice). This is not a sensitive secret like a PIN, so a
-- direct RLS-guarded insert is sufficient — no Edge Function required.
create policy "user_roles_insert_own"
  on public.user_roles
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- No update/delete policy: role removal (if ever needed) is an
-- administrative action, intentionally not exposed to clients yet.
