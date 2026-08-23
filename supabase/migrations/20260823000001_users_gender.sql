-- users.gender: 나이/성별 기반 맞춤 혜택 정보(정보 탭) 요구사항을 위해
-- 신규 추가한다. 계획 문서(2026-08-21 작성) 시점에는 users.age가 아직
-- 없었지만, 그 사이 20260822000001에서 profile_page 이름/나이 저장
-- 기능이 먼저 구현되며 age가 이미 추가됐다 — 이 migration은 gender만
-- 추가한다(age를 다시 add column 하면 "column already exists" 오류).
-- nullable — region_*/age와 동일하게 아직 입력하지 않은 사용자도
-- 존재한다(profile_page의 "저장" 흐름 참고). RLS는 이미
-- users_select_own/users_insert_own/users_update_own이 행 전체를
-- id = auth.uid() 기준으로 다루므로 정책을 추가하지 않는다.

alter table public.users
  add column if not exists gender text check (gender in ('male', 'female'));

comment on column public.users.gender is
  '어르신 성별(male/female) — 정보 탭의 맞춤 혜택 정보 검색 조건으로 쓰인다. profile_page에서 입력, 저장 전까지 null(미입력).';
