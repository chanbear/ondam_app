-- pin_credentials: PIN hash + lockout state. This table is the server-side
-- half of the "PIN brute force" defense (technical-decisions.md §1-3-A) —
-- it must NEVER be reachable by direct client SELECT/INSERT/UPDATE, only by
-- the SECURITY DEFINER functions in 20260812000003_pin_functions.sql,
-- called exclusively from the set-pin/verify-pin/reset-pin Edge Functions
-- using the service role key.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.pin_credentials (
  user_id uuid primary key references auth.users (id) on delete cascade,
  pin_hash text not null,
  failed_attempts integer not null default 0,
  locked_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.pin_credentials is
  'PIN hash (bcrypt via pgcrypto) and lockout state. No client role has direct access — see pin_functions.sql. failed_attempts/locked_until are the server-side source of truth; the client can never reset them.';

alter table public.pin_credentials enable row level security;

-- Deliberately no policies for `authenticated` or `anon`: RLS enabled with
-- zero grants means every direct client query is denied by default. Also
-- revoke the implicit table-level grants that come from `public` role
-- membership, as defense in depth beyond RLS alone.
revoke all on public.pin_credentials from authenticated, anon, public;
