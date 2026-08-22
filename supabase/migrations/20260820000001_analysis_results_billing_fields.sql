-- PHASE 37 — 요금/고지서 통계. `packages/models/lib/src/analysis_result.dart`의
-- `billingAmountKrw`/`billingDate` 필드는 이미 이 두 컬럼과 1:1 대응하도록
-- 설계되어 있었지만(주석 참고) 지금까지 실제 컬럼이 없었다 — 이번 migration으로
-- 그 설계를 실제로 연결한다.
--
-- `confirmed_at`(20260819000001)과 달리 client column-level grant를 추가하지
-- 않는다: 이 두 컬럼은 오직 `analyze-document` Edge Function이 service_role로
-- INSERT할 때만 채워지고, 이후 어떤 client도 수정할 수 없다(기존
-- confirmed_at 전용 column-level grant/정책은 그대로 유지 — 이 migration은
-- 건드리지 않는다). 기존 select 정책(본인 / accepted guardian)이 행 단위로
-- 이미 이 두 컬럼도 함께 노출하므로 별도 RLS 정책이 필요 없다.

alter table public.analysis_results
  add column if not exists billing_amount_krw integer,
  add column if not exists billing_date date;

comment on column public.analysis_results.billing_amount_krw is
  '문서에 실제로 인쇄된 청구/납부 금액(원) — AI가 신뢰성 있게 추출했을 때만 채워진다. null이면 금액을 추출하지 못했다는 뜻이며, 요금 통계 계산에서 제외해야 한다(가짜 0으로 대체 금지). message-type 레코드는 항상 null.';

comment on column public.analysis_results.billing_date is
  '문서에 실제로 인쇄된 청구/납부일 — 연-월-일이 모두 명시적으로 확인될 때만 채워진다. null이면 통계 집계 시 created_at을 기준 날짜로 대신 사용한다(임의로 연도를 추정하지 않는다).';
