# Technical Decisions — Architecture 확정 및 보안 요구사항

> 이 문서는 `feature-development` 착수 **이전** 단계 산출물이다. 실제 기능/API/DB/Provider 코드, Supabase 프로젝트, package 설치는 아직 진행하지 않는다.
>
> **개정 이력**
> - v1(초안): Backend/DB/인증/알림 등 11개 Architecture 결정 + 6개 UI 결정을 미확정 상태로 나열.
> - v2: 사용자가 Architecture 결정 11개 전체와 UI 결정 5개를 확정. 확정 내용을 반영하고, 남은 진짜 미확정 사항만 `OPEN QUESTIONS`로 분리했다.
> - v3: 신규 요구사항(음성 비서/쉬운 모드 Main 강화/카메라 플래시/답변 신뢰도/보호자 고지서 통계 동기화/관리자 시스템 PROPOSED)에 따른 미결정 사항 6개를 OPEN QUESTIONS에 추가하고, 전체 번호를 1~14로 재정리했다(§5).
> - v4(이 버전): Phase 1(프로젝트 기반 구축)에서 "어르신 앱/보호자 앱을 하나의 앱으로 만들지, 별도 앱으로 만들지"가 **별도 2개 Flutter 앱 + Monorepo**로 확정되어 OPEN QUESTIONS 6번을 해소 처리했다. Monorepo 도구는 melos 대신 Dart/Flutter native pub workspace를 채택했다(근거는 `architecture.md` "저장소 구조" 참고).
>
> 함께 읽는 문서: `docs/product/implementation-plan.md`(Phase별 실행 계획), `docs/product/feature-spec.md`, `docs/architecture/architecture.md`, `docs/ui/ui-spec.md`.

---

## 0. 확정 요약표

| # | 항목 | 확정 내용 |
|---|---|---|
| 1 | Backend | **Supabase** (커스텀 서버 미사용) |
| 2 | Database | **PostgreSQL** (Supabase 기본 제공) |
| 3 | 인증 | **전화번호 + OTP(가입 시) + PIN(평상시 로그인)**, 중요 작업(보호자 연결/계정 복구/보안정보 변경)에 추가 인증 |
| 4 | 보호자 알림 | **Push(FCM) 기본 + 서버에 알림 상태 저장**, SMS는 보조 수단으로 확장 가능하게 설계만 |
| 5 | 어르신-보호자 관계 | **어르신 1 : 보호자 N (1:N) 기본**, DB는 관계 테이블로 N:M 확장 여지를 막지 않음 |
| 6 | 보호자 연결 인증 | **어르신 수락(승인) 방식** — 전화번호만으로 즉시 연결 금지 |
| 7 | 위험 문자 판단 | **서버 측 AI 판단 기본**, API Key는 클라이언트에 절대 두지 않음(Edge Function 처리) |
| 8 | 사진/문서 원본 | **분석 완료 후 즉시 삭제 기본**, 사용자가 명시적으로 요청 시에만 별도 보관 정책 적용 가능하게 확장 설계 |
| 9 | Android SMS | **Android 전용 DataSource로 격리**, iOS는 직접 읽기 시도하지 않고 대체 Flow(붙여넣기/공유/직접입력/기능제한) |
| 10 | Push Notification | **FCM 사용**, 발송 로직은 서버에만 존재(클라이언트는 토큰 등록/수신/표시만) |
| 11 | Storage(로컬) | **Secure Storage(인증 민감정보) / Local Storage(쉬운모드 등 비민감 설정) 분리** |

| # | UI 결정 | 확정 내용 |
|---|---|---|
| A | 쉬운 모드 | **전체 앱 적용**(하단 네비 포함), 버튼크기/정보량/Navigation/화면복잡도/텍스트/여백/기능우선순위까지 바뀌는 별도 UX 모드. 글자크기 설정과 독립. 재실행 후 유지 |
| B | 긴급 버튼 색상 | `AppColors.error` 무조건 재사용 금지 — 필요 시 `emergency` 토큰 신설 가능(구조만 확정, 실제 색상값은 `ui-spec.md` 접근성 대비 검토 후 확정 — **값 자체는 OPEN**) |
| C | Empty State | **공통 `AppEmptyState` 컴포넌트**, 화면별 문구/아이콘/Action만 주입 |
| D | Loading | **상황별 병행**: 단순 로딩=Progress Indicator만 / 중요 작업=진행 상태 텍스트+Progress Indicator |
| E | 보호자 연결 전 화면 | **Mock 데이터 프리뷰는 프로덕션에서 사용 금지.** 연결 전에는 "아직 연결된 어르신이 없습니다 → 어르신 연결하기" Empty State로 대체 |

---

## 1. Architecture 결정 상세

### 1-1. Backend — Supabase 확정

**사유**(사용자 제시 근거 채택): PostgreSQL 기반 관계형 구조, Flutter 연동 편의성, Auth/Storage/Realtime/RLS를 하나의 플랫폼에서 제공, MVP 단계 운영 복잡도 최소화. 커스텀 서버는 현재 단계에서 사용하지 않는다.

> v1의 Firebase/커스텀서버 비교표는 참고 자료로만 남기고(§5), 실제 결정은 Supabase로 확정되었으므로 이후 모든 설계는 Supabase 전제로 서술한다.

### 1-2. Database — PostgreSQL 확정

Supabase의 PostgreSQL을 그대로 사용. 어르신/보호자/연결/분석/일정/알림을 관계형 테이블로 설계한다(테이블 목록은 §4).

### 1-3. 인증 — 전화번호 + OTP + PIN 확정

```
가입: 전화번호 입력 → OTP 인증 → PIN 설정 → 프로필 입력
평상시 로그인: 전화번호 + PIN
중요 작업(보호자 연결/계정 복구/보안정보 변경): 필요 시 OTP 등 추가 인증
```

- 평상시 로그인에 매번 OTP를 요구하지 않는 이유: 어르신 사용자의 접근성(문자 확인·입력 반복이 인지 부담)을 고려한 결정. **이 방향은 확정**이며, `feature-spec.md` KEEP-1("전화번호+PIN 로그인 유지")과 상충하지 않는다 — 가입 시 OTP 1회 추가 + 평상시는 기존과 동일한 PIN 로그인이므로 KEEP 항목은 "가입 시 OTP 추가"로 세부 보강만 필요(§6에서 갱신).
- PIN 자체의 저장/검증 메커니즘은 §2(보안 요구사항)에서 별도로 다룬다.

### 1-4. 보호자 알림 — Push 기본 + 서버 상태 저장 확정

```
이벤트 발생 → Backend → Notification 생성/저장 → FCM → 보호자 앱 Push
```

- SMS는 기본 알림 수단이 아니다. 향후 "긴급 상황/앱 미설치/푸시 미수신" 보조 수단으로 SMS를 추가할 수 있도록, 알림 발송 로직은 "발송 채널"을 추상화해 Push 외 채널을 나중에 끼워 넣을 수 있는 구조로 설계한다(예: `NotificationChannel` 인터페이스에 `PushChannel` 구현체를 우선 두고, 추후 `SmsChannel`을 추가).
- 이 결정으로 v1에서 지적했던 "SMS 수동발송 vs 서버 자동전달 혼재" 문제(`current-app-analysis.md` 2-10)가 해소된다. 기존 앱의 "이 기기의 문자 앱이 열리고, 내용이 미리 채워집니다" 문구는 신규 앱에서 사용하지 않는다.

### 1-5. 어르신-보호자 관계 — 1:N 기본, 확장 가능한 스키마

- 제품 UX 기본값: **어르신 1명 : 보호자 여러 명(N)**.
- DB는 `guardian_links` 관계 테이블로 구현해 향후 "보호자 1명이 여러 어르신 관리"(N:M)도 스키마 변경 없이 지원 가능하게 설계.
- 필수 요구사항(확정):
  1. 어르신이 자신에게 연결된 보호자 목록을 확인할 수 있어야 한다.
  2. 어르신이 보호자 연결을 해제할 수 있어야 한다.
  3. 보호자가 임의로(어르신 승인 없이) 연결되는 구조를 만들지 않는다(§1-6과 연결).
  4. 연결된 보호자에게는 필요한 최소 정보만 제공한다(요약 정보만, 비밀번호/설정 등 비공개 — 기존 앱 원칙 유지).
- `feature-spec.md`의 ADD(PROPOSED)-3("어르신 측 보호자 해제 기능")과 ADD(PROPOSED)-5("다중 보호자 등록 UI")는 이 결정으로 **PROPOSED에서 확정 요구사항으로 전환**한다(§6에서 `feature-spec.md` 갱신 반영).

### 1-6. 보호자 연결 인증 — 어르신 수락 방식 확정

```
보호자: 어르신 전화번호 또는 연결 코드 입력
  → 연결 요청 생성
  → 어르신 앱에 연결 요청 표시
  → 어르신 확인 → 수락
  → 연결 완료
```

- 전화번호만으로 즉시 연결되는 기존 프로토타입 방식은 사용하지 않는다.
- "전화번호" 또는 "연결 코드" 두 가지 입력 방식을 열어두되, 최종적으로 하나만 채택할지 병행할지는 `OPEN QUESTIONS`로 남긴다(§5의 2번).
- `guardian_links` 테이블은 `status: pending | accepted | rejected | revoked` 상태를 가져야 한다.
- `feature-spec.md`의 ADD(PROPOSED)-2("보호자 연결 2단계 인증")는 이 결정으로 **확정**(수락 방식 자체가 인증 장치) — 추가 OTP/연결 코드는 "필요하다면 추후 붙일 수 있도록 설계"까지만 확정, 최초 구현에 반드시 포함은 아님.

### 1-7. 위험 문자 판단 — 서버 측 AI 기본 확정

```
Android SMS → 앱에서 필요 데이터 추출 → Backend → Risk Detection(AI 분석)
  → 위험도/주의사유/요약 생성 → DB 저장 → 보호자 알림
```

- AI API Key 및 민감한 서버 인증 정보는 Flutter 앱에 절대 포함하지 않는다. Supabase **Edge Function**(또는 동등한 서버 환경)에서 처리.
- 이 결정으로 v1의 "Risk Detection 위치" 미정 상태가 해소된다.

### 1-8. 사진/문서 원본 — 즉시 삭제 기본 확정

```
원본 이미지 → 분석 → 필요한 결과만 저장 → 원본 삭제
```

- 사용자가 명시적으로 "문서 저장"을 요청하는 기능이 미래에 필요할 경우, 별도 보관 정책(보관 기간, 접근 권한)을 그때 설계한다 — 지금은 확장 여지만 남긴다.
- `technical-decisions.md` v1 §4-6("사진 원본 처리 정책")은 이 결정으로 해소.

### 1-9. Android SMS — 전용 DataSource 격리 확정

```
message_check/
├── domain/
├── data/
│   ├── repositories/
│   └── datasources/
│       ├── sms_datasource.dart   # Android 전용 구현
│       └── ...
```

- iOS에서는 수신 SMS 직접 읽기를 시도하지 않는다. iOS 대체 Flow: 붙여넣기 / 공유 / 사용자 직접 입력 / 기능 제한 중 실제 구현 시점에 선택.
- 실제 SMS 관련 패키지 선정은 **구현 Phase 착수 시점에 현재 Flutter/Android 정책을 재확인한 후 결정**한다(지금은 package 미설치 원칙 유지).

### 1-10. Push Notification — FCM 확정

```
Flutter: FCM Token 등록/갱신 → Push 수신 → 로컬 표시/Navigation
Backend: 알림 이벤트 생성 → 대상 사용자 확인 → Push 발송
```

- 실제 FCM 발송 로직(서버 키 사용)은 클라이언트에 절대 두지 않는다.
- Android/iOS 모두 지원.

### 1-11. Storage(로컬) — Secure/Local 분리 확정

```
Secure Storage → 인증 토큰 등 민감 정보
Local Storage  → 쉬운 모드, UI 설정, 비민감 사용자 설정
```

- 플랫폼별 적절한 보안 저장 방식 사용(`flutter_secure_storage` 등, 실제 패키지 선정은 구현 시점).
- `architecture.md`의 `core/storage` 단일 모듈 제안을 "책임은 하나의 core 모듈이 갖되 내부적으로 Secure/Local 두 저장소를 구분해 노출"하는 방식으로 구체화(§6에서 `architecture.md` 갱신 반영).

---

## 2. 보안/개인정보 요구사항 (구현 시 반드시 고려)

> 이 절은 "결정"이 아니라, 위 Architecture 결정을 실제로 구현할 때 **반드시 검토해야 할 체크리스트**다. 세부 구현 방법은 각 Phase 착수 시점에 확정한다.

1. **Supabase Auth로 전화번호 OTP + PIN 구조를 어떻게 구현할지**
   - Supabase Auth는 Phone OTP(가입/로그인 시 매번 문자 인증)를 네이티브로 지원하지만, "평상시에는 PIN만으로 로그인"이라는 요구사항은 Supabase 기본 흐름과 정확히 일치하지 않는다.
   - 검토 방향: (a) Supabase Phone OTP는 **가입 시 전화번호 소유 검증에만** 사용하고, 이후 로그인은 자체 PIN 검증 Edge Function(또는 Supabase Auth의 password 필드를 PIN 해시로 활용)으로 별도 세션을 발급하는 방식, (b) Supabase Auth 세션을 그대로 쓰되 PIN 검증을 거친 뒤에만 refresh token을 노출하는 방식. **최종 방식은 Phase 2 착수 시 결정**(§5의 1번).
2. **PIN을 어떻게 안전하게 관리할지**
   - PIN은 4자리 숫자로 전체 공간이 10,000가지뿐이라 무차별 대입에 매우 취약하다. 반드시 (a) 서버 측에서 해시(bcrypt/argon2 등) 저장, (b) 로그인 시도 횟수 제한/지수 백오프 또는 계정 잠금, (c) 클라이언트에 평문 PIN을 절대 저장하지 않을 것을 요구사항으로 명시한다.
3. **`guardian_links` RLS 정책**
   - 보호자는 `status = accepted`인 링크에 대해서만, 그것도 연결된 어르신의 **요약 데이터만** 조회 가능해야 한다.
   - 어르신은 자신에게 걸린 모든 링크(pending 포함)를 조회하고 상태를 변경(수락/거절/해제)할 수 있어야 한다.
   - 보호자가 `guardian_links`에 직접 `status='accepted'`를 쓰는 것은 금지(수락은 어르신만 가능) — RLS의 UPDATE 정책에서 강제해야 한다.
4. **어르신/보호자 개인정보 접근 범위**
   - 보호자에게 노출 가능한 필드 화이트리스트를 명시적으로 정의(이름/나이/지역/위험 알림 요약 등)하고, 비밀번호/PIN 해시/설정값 등은 어떤 경로로도 보호자에게 노출되지 않아야 한다(기존 앱의 "개인정보 보관 안내" 원칙과 일치).
5. **FCM Token 보안**
   - FCM 토큰은 기기별로 발급되며 탈취 시 임의 알림 수신이 가능하므로, 토큰-사용자 매핑 테이블에 대한 접근을 서버 내부 로직으로 한정하고 클라이언트/타 사용자에게 노출하지 않는다. 로그아웃/기기 변경 시 토큰 무효화 절차 필요.
6. **위험 문자 데이터 접근 권한**
   - 위험 문자 원문/분석 결과는 (a) 해당 어르신 본인, (b) `accepted` 상태의 연결된 보호자만 조회 가능해야 한다. 제3자 API나 로깅 시스템에 원문이 그대로 남지 않도록 주의(민감정보 포함 가능성).
7. **문서/사진 Storage 접근 정책**
   - 업로드된 사진은 분석 완료 전까지만 짧게 존재해야 하며(§1-8), Storage 버킷 정책도 "업로드한 본인 + 처리 중인 서버 함수"만 접근 가능하도록 제한. Signed URL의 만료 시간을 짧게 설정.
8. **Edge Function에서 AI API Key 관리**
   - AI 분석 API Key는 Supabase Edge Function의 환경변수(Secrets)로만 저장하고, 클라이언트로 전달되는 응답에 Key나 원본 프롬프트가 노출되지 않도록 응답 스키마를 최소화해야 한다.
9. **원본 이미지 즉시 삭제 정책**
   - "분석 완료 후 삭제"가 실제로 지켜지는지 보장하는 메커니즘(예: 분석 성공/실패와 무관하게 일정 시간 후 자동 삭제하는 Storage 수명주기 정책)을 함께 설계해, 분석 실패 시 원본이 무기한 남는 상황을 방지해야 한다.
10. **계정 탈퇴 시 연결/데이터 삭제 정책**
    - 어르신 계정 탈퇴 시: 본인 데이터 삭제 + 연결된 모든 `guardian_links` 해제(보호자 쪽에는 "연결이 종료되었습니다" 안내만 남기고 어르신 개인정보는 즉시 제거) 필요.
    - 보호자 계정 탈퇴 시: 어르신 데이터에는 영향 없이 해당 `guardian_links`만 해제.
    - 기존 앱의 "회원 탈퇴 시 계정과 함께 저장된 모든 정보가 서버에서 즉시 삭제된다"는 안내 문구와 일치하도록 설계.

---

## 3. Backend 플랫폼 비교 (참고 자료, 결정 완료)

> 아래 표는 §1-1 결정에 도달하기 위해 v1에서 작성한 비교 자료다. **결정은 이미 Supabase로 확정**되었으므로 실행 시 참고용으로만 유지한다.

| 항목 | Firebase | Supabase(확정) | 커스텀 서버(미채택) |
|---|---|---|---|
| DB 모델 | Firestore(NoSQL) | PostgreSQL(관계형) | PostgreSQL(자유 설계) |
| 관계 표현 | 번거로움 | FK로 자연스러움 | 자유롭지만 직접 구현 |
| 실시간 동기화 | Firestore 리스너 | Realtime | 직접 구축 필요 |
| Row-level 권한 | Security Rules | **RLS**(SQL 정책, 채택 근거) | 서버 코드로 직접 |
| 인증 | Firebase Auth | Supabase Auth(Phone OTP 지원) | 직접 구현/외부 연동 |
| 서버리스 함수 | Cloud Functions | Edge Functions | 자체 API |
| 운영 부담 | 낮음 | 낮음~중간 | 높음(미채택 사유) |

---

## 4. 확정 데이터 모델 개요 (설계 참고, 실제 스키마는 구현 시 확정)

> 코드/DDL은 작성하지 않는다. 표는 어떤 테이블이 필요한지에 대한 합의 수준의 개요다.

| 테이블(가칭) | 핵심 컬럼(예시) | 비고 |
|---|---|---|
| `users` | id, phone, pin_hash, role(elder/guardian), name, age, region, easy_mode_enabled | PIN은 반드시 해시로 저장(§2-2) |
| `guardian_links` | id, elder_id, guardian_id, status(pending/accepted/rejected/revoked), created_at, responded_at | §1-5, §1-6, §2-3 |
| `analysis_results` | id, elder_id, type(document/message), risk_level, summary, source_excerpt, **reliability(높음/보통/낮음 또는 원시 confidence, v3 추가)**, **structured_fields(고지서 금액/기한/항목 등 JSON, v3 추가)**, created_at | 원문 저장 범위는 §2-6과 함께 재검토. 신뢰도/구조화 필드의 정확한 스키마는 OPEN QUESTIONS 11, 12 |
| `schedules` | id, elder_id, title, due_at, completed_at, source_analysis_id(nullable) | 분석 기록에서 분리 — `docs/product/implementation-plan.md` §1 참고 |
| `notifications` | id, target_user_id, type, payload, read_at, sent_via(push/sms 등), created_at | §1-4 채널 확장 구조 반영 |
| `fcm_tokens` | id, user_id, token, device_info, updated_at | §2-5 |

---

## 5. OPEN QUESTIONS (아직 결정되지 않은 사항만)

> 위 §1의 Architecture 결정과 상충하지 않는 **세부 구현 방식** 수준의 질문만 남긴다. 제품/보안 방향은 모두 확정되었으므로, 아래는 각 Phase 착수 시점에 결정해도 전체 설계를 바꾸지 않는다.
>
> **v3 갱신**: 신규 요구사항(음성 비서/답변 신뢰도/보호자 고지서 통계/관리자 시스템) 관련 미결정 사항 6개를 추가하면서, 기존 항목과 번호가 겹치지 않도록 **전체를 1~14로 일괄 재정리**했다(카테고리별로 다시 1부터 시작하지 않음).

### Architecture 세부 (기존)

1. Supabase Auth의 Phone OTP를 가입 시 1회성 검증에만 쓰고 별도 PIN 세션 체계를 자체 구축할지, Supabase Auth 세션 자체를 PIN 검증 게이트 뒤에 두는 방식으로 재사용할지(§2-1).
2. 보호자 연결 요청 입력 방식으로 "전화번호"와 "연결 코드" 중 하나만 채택할지, 둘 다 지원할지(§1-6).
3. `notifications` 테이블에서 향후 SMS 채널을 추가할 때 채널별 재시도/우선순위 정책을 어떻게 둘지(지금은 구조만 확장 가능하게 설계, 정책은 미정).
4. Android SMS 접근에 사용할 실제 패키지/플러그인 선정(§1-9, 구현 착수 시점 재조사 원칙 유지).
5. `analysis_results`에 원문(문자 원문, OCR 텍스트)을 얼마나 오래/얼마나 상세히 저장할지(요약만 남길지, 원문도 일정 기간 남길지) — §2-6, §2-9와 연결된 세부 보관기간 정책.
6. ~~어르신 앱과 보호자 앱을 하나의 Flutter 앱으로 만들지, 별도 앱으로 만들지~~ → **해소(Phase 1)**: **별도 2개 Flutter 앱(`apps/senior`, `apps/guardian`) + Monorepo**로 확정. `packages/*`로 공통 코드를 공유하고, 두 앱은 서로 직접 import하지 않는다. 자세한 근거는 `architecture.md` "저장소 구조" 참고.

### UI 세부 (기존)

7. 긴급 버튼의 실제 색상값(`emergency` 토큰의 정확한 HEX) — 구조(토큰 신설 가능)는 확정, 값은 `ui-spec.md` 접근성 대비 검토 후 확정.
8. 쉬운 모드에서 하단 네비게이션 구성 자체(탭 개수/구성)를 바꿀지, 아이콘·크기만 바꿀지 — "변경할 수 있다"까지는 확정, 구체적 변경 범위는 실제 화면 설계 시 결정.

### 음성 비서 (신규, v3)

9. **STT/TTS 기술 및 서비스 선정**: 온디바이스(Android/iOS 내장 음성인식·합성 API) vs 클라우드 서비스(예: 상용 STT/TTS API) 중 무엇을 쓸지, 한국어 인식 정확도·비용·오프라인 지원 여부를 기준으로 검토 필요. 아직 어떤 서비스도 확정하지 않는다.
10. **음성 비서 AI 처리 방식**: 사용자의 음성 질문을 어떻게 "의도(intent)"로 분류해 온담 기능(문서 촬영 안내, 경로당 찾기 등)에 연결할지 — (a) 규칙 기반 키워드 매칭, (b) 서버 AI 모델에 의도 분류를 맡기는 방식, (c) 둘의 조합 중 선정 필요. §1-7(위험 문자 판단)과 동일하게 AI 처리는 서버 경유가 원칙이라는 점은 이미 확정.

### 답변 신뢰도 (신규, v3)

11. **신뢰도 산정 기준과 사용자 표현 방식**: 어떤 근거로 "높음/보통/낮음"을 나눌지(AI 모델의 원시 confidence score를 구간화할지, 별도 규칙을 둘지), 그리고 이를 "이 답변은 비교적 확실해요" 같은 문구로 매핑하는 정확한 규칙(UX Writing)을 어떻게 정의할지 — `ui-spec.md`에 별도 UX 규칙으로 정의하기로 했으나 구체적 기준표는 아직 없음.

### 보호자 고지서 통계 (신규, v3)

12. **고지서 통계의 최종 데이터 항목**: 월별 고지서/금액 변화/주요 항목/기간 대비 변화/이상 변화/분석 건수 중 최초 구현에 포함할 항목과 우선순위 — "별도 Feature Spec에서 결정"하기로 확정, 아직 그 Feature Spec은 작성되지 않음.

### 관리자 시스템 (신규, v3, PROPOSED 자체가 미결정)

13. 관리자 기능을 별도 관리자 앱(Flutter 등)으로 제공할지, 웹 관리자 페이지로 제공할지 결정 필요.
14. 관리자 시스템을 초기 MVP 범위에 포함할지, 완전히 제외하고 이후 로드맵으로 미룰지 결정 필요.

> 위 목록에 없는 항목(Backend, DB, 인증 큰 흐름, 알림 채널, 관계 카디널리티, 연결 인증 방식, 위험판단 주체, 원본 보관, SMS 격리, Push, 로컬 저장소 분리, 쉬운모드 범위/Main 격상, Empty State/Loading 정책, 미리보기 제거, 신규 기능 6개의 제품 방향, **어르신/보호자 앱 분리 구조**)은 **모두 확정**되었다. 위 14개 중 6번은 Phase 1에서 해소되어, 실질적으로 남은 것은 13개다. 나머지는 순수 **기술/세부 구현 방식** 미결정 사항이다.
