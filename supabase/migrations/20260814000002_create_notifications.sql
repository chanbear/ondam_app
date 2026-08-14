-- notifications: server-generated notification log, read by the Guardian
-- app's `notification` feature (technical-decisions.md §4, §1-4). Column
-- list matches the sketch there:
--   id, target_user_id, type, payload jsonb, read_at, sent_via, created_at
--
-- §1-4 확정: "이벤트 발생 → Backend → Notification 생성/저장 → FCM → 보호자
-- 앱 Push". A row here is the durable "was this notification sent" record;
-- `sent_via` is deliberately a free channel column (not a fixed enum tied
-- to today's push-only reality) so a future SMS fallback channel
-- (OPEN QUESTIONS #3) can be added without a schema change — only
-- `send-notification`'s channel dispatch logic changes.
--
-- Same posture as analysis_results (20260814000001): no client role ever
-- gets INSERT/UPDATE/DELETE here. A notification only ever exists because
-- some server-side flow (today: the send-notification Edge Function, via
-- service_role) decided to create one — never because a client wrote it
-- directly. service_role bypasses RLS entirely in Supabase, so no explicit
-- policy is needed for that write path.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  target_user_id uuid not null references auth.users (id) on delete cascade,
  type text not null,
  payload jsonb,
  read_at timestamptz,
  sent_via text not null default 'push' check (sent_via in ('push', 'sms')),
  created_at timestamptz not null default now()
);

comment on table public.notifications is
  'Server-generated notification log (technical-decisions.md §4, §1-4). Written only by service_role (send-notification Edge Function) — no client INSERT/UPDATE/DELETE policy exists, by design. `read_at` is therefore also not client-writable yet; marking-as-read would need its own RLS-gated column or RPC when that UX is actually built.';

create index if not exists notifications_target_user_id_created_at_idx
  on public.notifications (target_user_id, created_at desc);

alter table public.notifications enable row level security;

-- Only the target user may ever read their own notifications.
create policy "notifications_select_target_user"
  on public.notifications
  for select
  to authenticated
  using (target_user_id = auth.uid());

-- Deliberately no insert/update/delete policy for `authenticated`/`anon` —
-- see header comment. Rows come only from send-notification's service-role
-- write.
