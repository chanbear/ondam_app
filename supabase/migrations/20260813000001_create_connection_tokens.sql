-- connection_tokens: short-lived, single-use tokens backing the QR-based
-- Senior<->Guardian connection flow (technical-decisions.md §1-6 v9).
--
-- Same isolation posture as pin_credentials (20260812000002): this table
-- carries no PII by itself (just an opaque token + elder_id + timestamps),
-- but a leaked row would let anyone create a pending connection request
-- against that elder, so it gets the same "no client role has direct
-- access, only SECURITY DEFINER functions via service_role" treatment.

create table if not exists public.connection_tokens (
  token text primary key,
  elder_id uuid not null references auth.users (id) on delete cascade,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.connection_tokens is
  'Short-lived (issued for ~5 minutes), single-use tokens a Senior displays as a QR code so a Guardian can scan it to create a pending guardian_links row. No client role has direct access — see 20260813000002_connection_functions.sql.';

create index if not exists connection_tokens_elder_id_idx
  on public.connection_tokens (elder_id);

alter table public.connection_tokens enable row level security;

-- Deliberately no policies for `authenticated`/`anon` — same reasoning as
-- pin_credentials: RLS enabled with zero grants denies every direct client
-- query by default, and the explicit revoke below is defense in depth.
revoke all on public.connection_tokens from authenticated, anon, public;
