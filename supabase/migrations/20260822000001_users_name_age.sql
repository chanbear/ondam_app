-- users.name/age — the two columns technical-decisions.md §4 sketched
-- ("id, phone, name, age, region, easy_mode_enabled") but 20260819000002
-- deliberately left out until a Phase actually implemented saving them
-- (profile_page 이름/나이 입력은 "저장 준비 중" 안내만 하던 상태). This is
-- that Phase.
--
-- No CHECK constraint on age's range — validation belongs to the domain
-- layer (SaveProfileUseCase), not the schema, matching how region's three
-- text columns carry no format constraint either.

alter table public.users
  add column if not exists name text,
  add column if not exists age smallint;

comment on column public.users.name is
  '어르신 이름 — profile_page에서 입력/저장. RLS는 20260819000002의 users_select_own/insert_own/update_own 정책을 그대로 재사용한다(테이블 단위 정책이라 컬럼 추가로 재설정 불필요).';

comment on column public.users.age is
  '어르신 나이 — profile_page에서 입력/저장. 범위 검증은 SaveProfileUseCase(도메인 계층)의 책임.';
