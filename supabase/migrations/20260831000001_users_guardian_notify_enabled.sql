-- users.guardian_notify_enabled: "알림 설정"(notif-settings) 화면의 "보호자
-- 알림" 토글이 저장할 곳. 위험 알림(위험도 표시 자체)은 항상 켜져 있고
-- 토글 대상이 아니다 — 이 컬럼은 "위험/주의로 분석된 문자를 확인했을 때
-- 연결된 보호자에게도 알릴지"만 결정한다(message_risk_repository_impl.dart의
-- notifyGuardian 호출부 참고).
-- 기본값 true — 안전을 우선하는 기능이라 옵트인이 아니라 옵트아웃으로
-- 설계(꺼두려면 직접 알림 설정에서 꺼야 함). nullable이 아니다 — region/age
-- 처럼 "아직 입력 안 함" 상태가 의미 있는 값이 아니라, 언제나 on/off 둘 중
-- 하나로 확정돼야 하는 설정이기 때문.
alter table public.users
  add column if not exists guardian_notify_enabled boolean not null default true;

comment on column public.users.guardian_notify_enabled is
  '위험/주의로 분석된 문서·문자 결과를 확인했을 때 연결된 보호자에게도 알림을 보낼지 여부. 기본 true, 알림 설정 화면에서 토글.';
