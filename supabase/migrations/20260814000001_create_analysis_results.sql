-- analysis_results: document/message analysis output, produced by the
-- Senior app's `document_scan`/`message_check` features and read by the
-- Guardian app's `analysis` feature (records/statistics). Column list
-- matches the sketch in docs/architecture/technical-decisions.md §4.
--
-- No INSERT/UPDATE/DELETE policy for any client role, by design: writing a
-- row requires an actual AI analysis to have happened, which per §1-7 only
-- ever runs server-side (Edge Function, AI API key never reaches the
-- client). Phase 4's `AnalysisRepository.analyzeDocument()` already always
-- returns `UnavailableFailure` because that Edge Function does not exist
-- yet — so this table exists and is queryable, but will have zero real
-- rows until that backend is actually built. Guardian's `analysis` feature
-- must render a real (not fabricated) Empty State for that reason, not a
-- placeholder pretending data exists.

create table if not exists public.analysis_results (
  id uuid primary key default gen_random_uuid(),
  elder_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('document', 'message')),
  risk_level text check (risk_level in ('safe', 'caution', 'dangerous')),
  summary text not null,
  source_excerpt text,
  reliability text not null check (reliability in ('high', 'medium', 'low')),
  structured_fields jsonb,
  created_at timestamptz not null default now()
);

comment on table public.analysis_results is
  'Document/message analysis output (technical-decisions.md §4). risk_level is only meaningful for message-type rows today (mirrors packages/models AnalysisResult.riskLevel). structured_fields is intentionally schema-less (billing statistics field list is still OPEN QUESTIONS #12) — consumers must render it generically (key/value), never assume specific keys.';

create index if not exists analysis_results_elder_id_created_at_idx
  on public.analysis_results (elder_id, created_at desc);

alter table public.analysis_results enable row level security;

-- (a) the elder themself.
create policy "analysis_results_select_elder"
  on public.analysis_results
  for select
  to authenticated
  using (elder_id = auth.uid());

-- (b) a guardian, but ONLY through an accepted guardian_links row — never
-- via role membership alone (technical-decisions.md §2 item 6: "위험 문자
-- 원문/분석 결과는 (a) 해당 어르신 본인, (b) accepted 상태의 연결된
-- 보호자만 조회 가능해야 한다"). A pending/rejected/revoked link grants no
-- access — this subquery only ever matches rows where status = 'accepted'.
create policy "analysis_results_select_accepted_guardian"
  on public.analysis_results
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

-- Deliberately no insert/update/delete policy for `authenticated`/`anon` —
-- rows are written by a future server-side AI pipeline (service_role /
-- Edge Function), not by any client. Revoking a guardian_link immediately
-- removes that guardian's access on the next query (no separate cleanup
-- needed) since policy (b) re-evaluates `status = 'accepted'` every time.
