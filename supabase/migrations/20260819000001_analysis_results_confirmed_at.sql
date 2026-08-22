-- ONDAM 2.0 요구사항 20/29 — "확인 완료" 상태를 실제로 영속화한다. 기존
-- analysis_results 테이블은 INSERT/UPDATE 정책이 전혀 없다(server-side AI
-- 파이프라인만 행을 쓴다는 설계, 20260814000001 참고) — 이 컬럼 하나만은
-- 본인 소유 행에 한해 어르신 본인이 직접 표시할 수 있어야 하므로, RLS로
-- 행을 elder_id 소유로 제한하고 컬럼 권한(column privilege)으로 이
-- confirmed_at 컬럼만 쓸 수 있게 좁힌다 — summary/risk_level 등 다른
-- 컬럼은 여전히 클라이언트가 절대 쓸 수 없다.

alter table public.analysis_results
  add column if not exists confirmed_at timestamptz;

comment on column public.analysis_results.confirmed_at is
  '어르신 본인이 결과 화면에서 "확인 완료"를 누른 시각. null이면 아직 확인 안 함. 이 컬럼 외에는 어떤 컬럼도 클라이언트가 직접 쓸 수 없다(아래 grant 참고).';

create policy "analysis_results_update_confirm_own"
  on public.analysis_results
  for update
  to authenticated
  using (elder_id = auth.uid())
  with check (elder_id = auth.uid());

-- RLS는 "어느 행"을 막을 뿐 "어느 컬럼"까지는 막지 못한다 — 컬럼 권한으로
-- confirmed_at 하나만 실제로 쓸 수 있게 좁힌다.
--
-- 주의(PHASE 28 검토에서 발견): authenticated 롤은 Supabase 프로젝트의
-- 기본 권한 부트스트랩(`alter default privileges ... grant ... to
-- authenticated`)으로 이미 이 테이블 전체에 대한 UPDATE grant를 갖고
-- 있다 — user_roles/guardian_links 등 다른 테이블이 별도 grant 문 없이
-- RLS의 insert/update policy만으로 실제 동작하는 것이 그 증거다(예:
-- 20260813000003_guardian_links_write_policies.sql의
-- guardian_links_update_party 정책에는 grant 문이 전혀 없다). 즉 아래
-- column-level grant를 "추가"하기 전에 테이블 전체 update 권한을 먼저
-- revoke하지 않으면, 이 파일이 새로 여는 update RLS policy를 통해
-- summary/risk_level 등 다른 컬럼까지 함께 쓸 수 있는 실제 보안 허점이
-- 생긴다(RLS의 with check는 행 단위 조건만 검사하고 컬럼 단위는 검사하지
-- 않는다). 반드시 revoke를 먼저 실행한 뒤 column-level grant를 추가해야
-- "confirmed_at만 쓸 수 있다"는 위 컬럼 주석의 설명이 실제로 성립한다.
revoke update on public.analysis_results from authenticated;

grant update (confirmed_at) on public.analysis_results to authenticated;
