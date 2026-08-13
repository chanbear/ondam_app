# Architecture (기능 반영)

> 저장소 전반의 아키텍처 규칙은 `.claude/rules/architecture.md`에 있다. 이 문서는 `feature-spec.md`, `docs/architecture/technical-decisions.md`(Architecture 결정 확정본)에서 도출된 기능들이 실제 저장소 구조에 어떻게 적재될지를 정리한다.
>
> **개정 이력**: v1은 Backend/DB/인증/연결 방식 등이 미확정인 상태의 "제안"이었다. v2에서 Backend(Supabase)/DB(PostgreSQL)/인증(OTP+PIN)/연결(어르신 수락)/알림(Push+서버) 등이 확정되었다. v3에서는 신규 요구사항(음성 비서/쉬운 모드 Main 강화/카메라 플래시/답변 신뢰도/보호자 고지서 통계 동기화/관리자 시스템 PROPOSED)을 반영했다. v4: Phase 1에서 "어르신 앱/보호자 앱을 하나의 Flutter 앱으로 만들지, 별도 앱으로 만들지" 결정이 **별도 2개 Flutter 앱(Monorepo)로 확정**되어, 아래 구조 전체를 `lib/features/` 단일 트리에서 `apps/senior/lib/features/` + `apps/guardian/lib/features/` + `packages/*` 구조로 갱신했다. v5: Phase 2 착수 전 Authentication Architecture(OTP+PIN+Session 결합 방식, B안)를 확정하고 "Authentication Architecture" 절을 추가했다. v6: Authentication 관련 남은 OPEN QUESTIONS(PIN 해시 알고리즘/Role 동시허용/idle timeout)를 실제 기술 조사를 거쳐 확정했다(PIN 해시는 Argon2id→bcrypt(pgcrypto)로 변경). v7: Phase 2(Authentication)를 실제로 구현했다 — "Authentication Architecture" 절 하단에 "실제 구현된 구조(v7)"를 추가했다. v8: Phase 3(Senior/Guardian UI 골격)에 이어 Phase 4(문서 촬영 카메라+분석 요청 골격)를 구현했다 — "Camera Architecture" 절을 신규 추가했다. v9: Phase 5(Connection) 착수 전 연결 요청 트리거를 **QR 코드 기반**으로 확정(`technical-decisions.md` §1-6 v9) — "어르신↔보호자 연결(QR)" 절을 신규 추가했다. **v10(이 버전)**: Phase 6(Guardian 핵심 기능 + 고지서 통계)을 구현했다 — `analysis` feature의 Guardian 쪽을 실제로 만들고(Senior 쪽은 아직 미승격), 계획했던 별도 `guardian/` feature 대신 기존 `home/` 4탭이 `analysis`를 조회하는 구조로 정리했다(Feature 매핑 표 참고). 세부 실행 계획은 `docs/product/implementation-plan.md`를 참고.

## 저장소 구조 (v4 확정)

```text
ondam/
├── apps/
│   ├── senior/      # 온담 어르신 앱 — 독립 Flutter 앱, 독립 android/ios, 독립 router
│   └── guardian/    # 온담 보호자 앱 — 독립 Flutter 앱, 독립 android/ios, 독립 router
├── packages/
│   ├── core/            # Failure 등 프레임워크 비의존 공용 타입 (pure Dart)
│   ├── design_system/   # AppColors/AppTextStyles/AppSpacing/AppRadius/AppTheme + 공용 위젯 (Flutter)
│   ├── models/           # AnalysisResult/GuardianLink 등 두 앱이 공유하는 모델 (pure Dart)
│   ├── network/          # DioClient/NetworkException/ErrorInterceptor (pure Dart)
│   ├── storage/          # SecureStorageService/LocalStorageService (Flutter)
│   └── shared/           # 현재 비어있음 — 실제 공통 유틸 필요 시 채움
└── docs/
```

두 앱은 서로 직접 import하지 않는다(`apps/senior`가 `apps/guardian`의 코드를 참조하지 않고, 반대도 마찬가지). 공유가 필요한 코드는 `packages/*`로 승격하고, `packages/*`는 어떤 `apps/*`도 참조하지 않는다(의존 방향이 거꾸로 되는 것을 방지 — 예: `packages/network`의 `DioClient`는 `baseUrl`을 생성자 파라미터로 받고, 각 앱의 `AppConfig`를 직접 참조하지 않는다).

Monorepo 도구는 **melos를 쓰지 않고 Dart/Flutter의 native pub workspace**(`pubspec.yaml`의 `workspace:` 필드, Dart 3.6+/Flutter 3.27+ 지원)를 사용한다. 이유:
- 이 저장소의 Flutter 3.44.9/Dart 3.12.2는 workspace 기능을 완전히 지원하며, 실제로 루트에서 `flutter pub get` 한 번으로 8개 워크스페이스 멤버(앱 2개+패키지 6개) 전체가 하나의 lockfile로 resolve됨을 확인했다.
- melos는 버전 관리/체인지로그/스크립트 러너 등 pub.dev에 실제 배포하는 멀티패키지 생태계에 유용한 기능을 제공하지만, 온담은 각 앱을 독립적으로 `flutter analyze`/`flutter test`/`flutter build`하는 것으로 충분해 melos의 부가 기능이 필요하지 않다.
- 외부 도구를 추가로 설치하지 않아도 되므로 "필요한 package만 설치" 원칙에 부합한다.

## Feature 매핑 (확정된 Architecture 결정 반영)

> 아래 "위치" 열은 실제 경로를 `apps/senior/lib/features/<name>/` 또는 `apps/guardian/lib/features/<name>/`로 읽는다(길어서 표에서는 `<name>/`만 표기).

| Feature | 앱 | 위치 | 의존하는 core/패키지 | 비고 |
|---|---|---|---|---|
| 인증(로그인/가입) | 어르신+보호자 각자 | `<app>/lib/features/auth/` | `ondam_network`, `ondam_storage`(Secure — Session은 Supabase SDK가 자체 관리) | 전화번호+OTP(가입 1회)+PIN(평상시), 소셜 로그인. 양쪽 앱이 각자 구현(코드 공유 아님, Backend API 계약만 공유). **확정(v5, `technical-decisions.md` §1-3-A)**: PIN 검증은 Backend Edge Function 전담(B안), Session은 Supabase 표준 그대로. "앱 재진입 PIN 게이트"는 각 앱의 `app/router/`(redirect 콜백)와 `core/auth/pin_verified_provider.dart`(신규, Phase 2)로 구현 |
| 온보딩(접근성/프로필/보호자 등록 요청) | 어르신+보호자 각자 | `<app>/lib/features/onboarding/` | `ondam_network`, `ondam_storage`(Local) | auth 이후 1회성 흐름. 보호자 등록은 "즉시 연결"이 아니라 `connection` feature의 요청 생성 UseCase를 호출 |
| 내 정보 | 어르신+보호자 각자 | `<app>/lib/features/profile/` | `ondam_network` | `onboarding`/`settings`와 데이터 소유 공유(같은 앱 내에서) |
| 홈(어르신, 일반/쉬운 모드) | 어르신 전용 | `apps/senior/lib/features/home/` | `ondam_design_system` | 쉬운 모드 상태는 `easyModeProvider`(`apps/senior/lib/core/easy_mode/`)로 앱 전역 `keepAlive` Provider 사용(확정, Phase 1에 기반 구현됨). 쉬운 모드가 홈의 Main UX로 격상되어, 일반 모드보다 쉬운 모드/음성 비서 진입 동선을 우선 설계해야 함 |
| 문서 촬영/AI 분석 | 어르신 전용 | `apps/senior/lib/features/document_scan/` | `ondam_core`, `ondam_models`, `camera`, `permission_handler` | **v8 구현 완료(카메라+권한+화면 골격)**: 촬영/재촬영/플래시(ON/OFF/자동)까지 실제 동작. 분석 요청은 백엔드가 없어 항상 `UnavailableFailure` — 원본 즉시 삭제 정책(§1-8)은 실제 업로드 자체가 없는 이 시점엔 해당 없음(업로드 구현 시 재검토). 상세는 §"Camera Architecture" |
| 문자 내용 요약 | 어르신 전용 | `apps/senior/lib/features/message_check/` | `ondam_core`, `ondam_models`, `ondam_design_system` | **Phase 7 구현 완료.** SMS 자동 조회는 Android 전용, `data/datasources/android_sms_datasource.dart`(`flutter_sms_inbox`)+`sms_permission_datasource.dart`(`permission_handler`)로 격리하고 `data/repositories/sms_inbox_repository_factory.dart`(`Platform.isAndroid`)에서만 플랫폼을 분기한다(확정, §1-9). iOS는 대안 UX 중 **붙여넣기+직접입력**을 채택(공유하기/기능제한은 미채택). 분석 요청(`MessageRiskRepository`)은 백엔드 부재로 항상 `UnavailableFailure` — `ondam_network`를 아직 쓰지 않는다(호출할 API가 없음) |
| 복지센터·경로당 찾기 | 어르신 전용 | `apps/senior/lib/features/welfare_center/` | `ondam_network`, `core/location`(앱 내 신규, 아직 없음) | 위치 기반 + 주소 검색 폴백 |
| 맞춤 정보(정보 탭) | 어르신 전용 | `apps/senior/lib/features/info/` | `ondam_network` | 나이 기반 개인화 |
| 분석 기록(`analysis`) | 어르신+보호자 **각자** | `apps/guardian/lib/features/analysis/`(**v10 구현 완료** — 조회) + Senior 쪽은 아직 별도 feature 없음(생성/표시 로직이 `document_scan`에 남아 있음, 아래 비고) | `ondam_network`, `ondam_models`의 `AnalysisResult`/`AnalysisType`/`ReliabilityLevel`/`RiskLevel` | 기존 `records`에서 개명. 문서/문자 분석 결과 통합, 고지서 통계 포함. `analysis_results` 테이블과 대응(§4, v10에서 실제 migration 완료). **두 앱이 같은 이름의 feature를 각자 갖되 코드는 공유하지 않는다** — 모양만 `packages/models`의 `AnalysisResult`로 통일하고, 실제 데이터는 Backend를 통해서만 오간다. `AnalysisResult`/`AnalysisType`/`ReliabilityLevel`/`RiskLevel`에 신뢰도 메타데이터, 고지서 통계용 구조화 필드(`structuredFields`), db-value 매핑이 존재. **Senior 쪽 `analysis` feature는 계획과 달리 아직 별도로 승격되지 않았다** — Phase 4가 결과 표시(`AnalysisResultView`)를 `document_scan/presentation/`에 남겨뒀고 실제 writer(AI 백엔드)가 없어 승격할 실익이 아직 없었다. 실제 분석 백엔드가 생기는 시점에 재검토 |
| 일정(`schedule`) | 어르신+보호자 각자 | `<app>/lib/features/schedule/` | `ondam_network` | `analysis`에서 분리(확정, `feature-spec.md` MODIFY-9). `schedules` 테이블과 대응. `Schedule` 공유 모델은 아직 `ondam_models`에 없음 — Phase 4(schedule 착수 시점)에 추가 |
| 어르신↔보호자 연결(`connection`) | **어르신+보호자 각자** | `apps/senior/lib/features/connection/` + `apps/guardian/lib/features/connection/` | `ondam_network`, `ondam_models`의 `GuardianLink`/`GuardianLinkStatus` | `guardian_links`(pending/accepted/rejected/revoked) 개념을 양쪽 앱이 공유 모델(`packages/models`)로만 공유하고 구현은 각자 한다. 어르신 측 "보호자 목록/해제" UI, 보호자 측 "연결 요청" UI 모두 이 feature가 담당. **v1~v3 문서에서는 Guardian App에만 있는 것처럼 서술된 부분이 있었는데, Senior App에도 반드시 필요하다 — Phase 1에서 두 앱 모두에 `connection/` 디렉터리를 생성해 이 불일치를 바로잡았다.** **v9: 연결 요청 트리거가 QR 코드 기반으로 확정됨에 따라 Senior 쪽은 QR 표시, Guardian 쪽은 QR 스캔 책임이 추가된다 — 상세는 아래 "어르신↔보호자 연결(QR)" 절.** |
| 보호자(`guardian`) | 보호자 전용 | **별도 `guardian/` feature로 만들지 않음(v10)** — `apps/guardian/lib/features/home/`(탭 4개: 홈/알림/기록/통계)이 조립만 담당, 실제 데이터는 `analysis`/`connection`이 소유 | `ondam_network`, `ondam_models` | 원래 계획은 `features/guardian/`이었으나, 홈/알림/기록/통계 4탭이 전부 `analysis`(+`connection`)의 데이터를 그대로 보여주기만 하고 자체 도메인/데이터 계층이 없어, 계획했던 별도 feature 폴더를 만들 실익이 없었다(architecture.md "Feature 간 결합 최소화" 원칙 — 존재하지 않는 도메인을 위해 빈 feature 골격을 먼저 만들지 않는다). `home/`은 Phase 3부터 이미 존재하던 탭 셸을 그대로 재사용. Mock 프리뷰 화면은 만들지 않음(확정). "통계" 화면은 `analysis`의 `analysis_results`를 조회해 스키마 무관 집계(건수)만 표시 — 고지서 통계 항목 자체는 OPEN QUESTIONS #12로 여전히 미확정이라 구조화 필드는 제네릭 나열까지만 |
| 긴급 도움 | 어르신 전용(보호자 필요 여부는 확인 필요) | `apps/senior/lib/features/emergency_help/` | `ondam_design_system` | 로직(연락처 조회, tel: 링크)은 feature에 유지, UI 위젯만 `ondam_design_system`로 승격 |
| 알림(`notification`) | 보호자 전용(어르신 쪽 필요 여부는 위험 알림 외 확인 필요) | `apps/guardian/lib/features/notification/` | `ondam_network`, `ondam_storage`(FCM 토큰 캐시 등) | FCM 토큰 등록/수신/로컬표시/딥링크 담당. 발송 로직은 서버(Edge Function)에만 존재 |
| **음성 비서(`voice_assistant`)** | 어르신 전용 | `apps/senior/lib/features/voice_assistant/` | `ondam_network` | 음성 입력(STT)을 받아 의도를 분석하고, 다른 feature의 UseCase를 호출하거나 AI 응답을 받아 TTS로 출력. 다른 feature를 폭넓게 알아야 하는 오케스트레이션 성격이라 core/패키지가 아닌 독립 feature로 배치(§"신규 요구사항 Architecture 반영" 참고) |
| 설정(글자크기/음성/계정/언어/보호자정보/알림) | 어르신+보호자 각자 | `<app>/lib/features/settings/` | `ondam_network`, `ondam_storage`(Secure+Local 모두 사용) | 접근성 설정은 Local, 계정/토큰 관련은 Secure |
| 지원(`support`) | 어르신+보호자 각자 | `<app>/lib/features/support/` | `ondam_network` | 사용 방법 안내, 고객센터, 개인정보 보관 안내 |

### Feature 간 결합에 대한 메모

- `guardian`(App)은 `connection`, `analysis`, `schedule`이 Backend에 만들어낸 데이터를 조회만 한다. **같은 이름의 feature가 두 앱에 모두 있어도 코드를 공유하지 않는다** — 공유되는 것은 오직 `packages/models`의 타입 모양(`AnalysisResult`, `GuardianLink` 등)과 Backend API 계약뿐이다. `apps/guardian`이 `apps/senior`의 `lib/features/analysis/` 코드를 import하는 일은 없다(있다면 모노레포 원칙 위반).
- `emergency_help`의 "보호자에게 전화" 기능은 `connection`이 소유한 연결된 보호자 목록에서 연락처를 읽어야 한다(보호자 정보의 실제 source of truth는 `connection`의 `guardian_links`로 확정 — `settings`는 이를 표시/편집하는 화면만 제공).
- `message_check`가 감지한 위험 문자는 `analysis`에 저장되고, 어르신이 "보호자에게 알리기"를 누르면(Backend 경유로) 보호자 앱의 `notification`이 알림 이벤트를 수신한다. `message_check` → `analysis` → Backend → `notification` 순서. **Phase 7 구현 상태**: `message_check`는 완료됐지만 이 파이프라인의 뒷단(위험 분석 Edge Function, `analysis`에 실제 저장, `notification`)은 아직 없어 오늘은 `message_check`에서 분석 요청이 항상 `UnavailableFailure`로 끝난다 — Guardian 쪽 `analysis` feature는 (미래에 이 파이프라인이 채워지면) 코드 변경 없이 그대로 `AnalysisType.message` 행을 표시할 준비가 이미 되어 있다(Phase 6에서 선반영, 코드 확인 완료).

## Authentication Architecture (v6 확정 → v7 구현 완료)

> `technical-decisions.md` §1-3-A의 전체 설계를 요약한다. 상세 흐름/정책 수치는 그 문서가 원본이다. 여기서는 저장소 구조 관점에서 어디에 무엇이 위치하는지만 정리한다.
>
> **v6 갱신**: PIN 해시를 Argon2id에서 **bcrypt(pgcrypto)**로 변경(Supabase Edge Function 2초 CPU 제한 + Deno Argon2 라이브러리 성숙도 부족이 근거), Role 동시허용(B안) 확정, 앱 재진입 idle timeout(Senior 15분/Guardian 5분) 확정.
> **v7 갱신**: 아래 설계를 실제로 구현했다. 실제 파일 경로는 이 절 하단 "실제 구현된 구조(v7)" 참고.

```
전화번호
  ↓
OTP 본인 확인 (Supabase Phone Auth — 가입/새기기/PIN분실 등 보안 이벤트에서만)
  ↓
계정 확인
  ├─ 신규 → PIN 설정(`set-pin` Edge Function) → 계정 생성
  └─ 기존(같은 기기, Session 유효) → PIN 입력(`verify-pin` Edge Function) → 앱 재진입 게이트 해제
  ↓
Supabase Auth Session (SDK가 표준대로 관리 — 앱은 이 동작에 개입하지 않음)
```

- **Session**과 **PIN 게이트 상태**는 완전히 분리된 두 개념(원칙 7). Session은 Supabase SDK 표준 동작, PIN 게이트는 각 앱의 순수 인메모리 Provider(`pinVerifiedProvider`, 디스크 비영속)로 구현하고 라우터 `redirect`로 화면 접근을 제어한다. **v6 확정**: 이 게이트는 Senior 앱에서 15분, Guardian 앱에서 5분의 idle timeout 후 다시 잠긴다(고정값, 설정 UI는 미제공 — OPEN QUESTIONS 19).
- 필요한 Edge Function(Phase 2에서 실제 작성, 지금은 설계만): `set-pin`(가입 시 PIN 최초 등록), `verify-pin`(평상시 재진입 PIN 검증 + lockout 관리), `reset-pin`(OTP 재인증 후 PIN 재설정), `delete-account`(계정 탈퇴 시 `pin_credentials`/`user_roles`/Auth 유저 연쇄 삭제). **v6 확정**: 이 Edge Function들은 PIN 해시 계산을 직접 하지 않고, **PostgreSQL `pgcrypto` 확장을 쓰는 `SECURITY DEFINER` DB 함수**(`set_pin`/`verify_pin` 등)를 호출하는 얇은 오케스트레이션 계층으로 설계한다 — Deno/WASM Argon2 라이브러리의 호환성 리스크와 Edge Function의 2초 CPU 제한을 동시에 피하기 위함(근거: `technical-decisions.md` §1-3-A "PIN 해시 알고리즘 기술 검증").
- **Role 관리**: `auth.users`는 Senior/Guardian 두 앱이 공유하는 단일 사용자 풀. Role은 앱 종류가 아니라 `user_roles` 테이블(신규)로 판단하며, RLS는 요청이 어느 앱에서 왔는지를 절대 신뢰하지 않고 `user_roles`의 실제 데이터로 권한을 검사한다. **v6 확정**: 동일 전화번호가 Senior+Guardian role을 동시에 가질 수 있다(B안). 온보딩에서 이미 다른 role로 가입된 번호일 경우 안내 문구를 표시하되 막지 않는다. `guardian_links`에는 `elder_id != guardian_id` 제약을 추가해 자기 자신을 보호자로 연결하는 것을 방지한다.
- **Guardian 생체인증(지문/FaceID)은 Phase 2 범위에 포함하지 않는다** — 채택 여부 자체가 OPEN QUESTIONS 18로 남아있다. 포함하게 될 경우 PIN을 로컬에 저장하지 않는다는 원칙(§1-3-A 원칙 4)을 지키려면 별도의 생체인증 전용 device credential 설계가 추가로 필요하다는 점만 기록해둔다.

### 실제 구현된 구조 (v7)

각 앱(`apps/senior`, `apps/guardian`)에 동일한 구조로 독립 구현했다(서로 import하지 않음):

```
apps/<app>/lib/
├── core/auth/
│   ├── supabase_client_provider.dart   # Supabase.instance.client를 Riverpod에 노출
│   ├── auth_state_provider.dart        # Supabase Auth 상태 스트림 (StreamProvider)
│   ├── pin_verified_provider.dart      # 메모리 전용 PIN 게이트 (Notifier<bool>)
│   ├── auth_constants.dart             # idle timeout 상수 (Senior 15분 / Guardian 5분)
│   └── idle_timeout_controller.dart    # AppLifecycleListener + shouldRelock() 순수 함수
├── app/router/
│   ├── auth_routes.dart                # 경로 상수
│   ├── auth_redirect.dart              # decideAuthRedirect() 순수 함수 (유닛 테스트 대상)
│   └── app_router.dart                 # redirect 콜백 + refreshListenable 배선
└── features/auth/
    ├── domain/
    │   ├── entities/pin_verify_result.dart
    │   ├── repositories/auth_repository.dart
    │   ├── usecases/  (request_otp, verify_otp, sign_out, set_pin, verify_pin,
    │   │               reset_pin, has_pin, delete_account, add_role, get_roles)
    │   └── utils/phone_number_formatter.dart
    ├── data/
    │   ├── datasources/auth_remote_datasource.dart   # Supabase Auth SDK + user_roles 테이블
    │   ├── datasources/pin_remote_datasource.dart    # functions.invoke()로 Edge Function 호출
    │   └── repositories/auth_repository_impl.dart    # SDK 예외 → Failure 매핑
    └── presentation/
        ├── providers/  (DI wiring, OtpNotifier, PinNotifier, RoleNotifier, hasPinProvider)
        ├── pages/      (phone_input, otp_verify, pin_setup, pin_entry, pin_forgot,
        │                role_select, session_loading)
        └── widgets/pin_keypad.dart   # feature-local, Senior 76px / Guardian 56px 버튼
```

`packages/core`에 `Result<T>`(`Ok`/`Err`)를 추가했다 — `dartz`/`fpdart`가 없어 api.md의 "Either 또는 이에 준하는 명시적 성공/실패 표현" 요구를 충족하는 최소 구현. `packages/models`에 `UserRole` enum을 추가했다.

라우터 상태 분기(`decideAuthRedirect`): No Session → phone/OTP 허용, Session+PIN 미설정 → PIN 설정, Session+PIN 설정+미검증 → PIN 입력, Session+PIN 검증+role 없음 → role 선택, 그 외 → home(Phase 3 placeholder, `_PlaceholderHomePage`). PIN 분실 흐름(`/auth/pin/forgot`)은 세션이 있어도 이 분기를 우회하도록 예외 처리하고, 완료 시 `context.go(home)`으로 명시적으로 빠져나온다.

## 신규 core 모듈 / 패키지 필요 여부 (확정 반영, Phase 1에서 구현됨)

- **`packages/storage`(`ondam_storage`)**: `technical-decisions.md` §1-11에 따라 **Secure Storage(인증 토큰 등 민감정보)와 Local Storage(쉬운모드/글자크기 등 비민감 설정)를 논리적으로 분리**해 노출. `SecureStorageService`/`LocalStorageService` 두 클래스로 구현 완료(Phase 1). 실제 인증 토큰 사용은 Phase 2.
- **각 앱의 `core/location`**: `welfare_center`, `onboarding`(현재 위치 입력) 등 어르신 앱 내 2개 이상 feature가 위치 조회를 필요로 하므로, 앱 내부 `core/location`(아직 미구현, Phase 4에서 실제 착수)으로 공유 예정. 보호자 앱에는 위치 기능이 없어 이 모듈은 `packages/`가 아니라 `apps/senior` 앱 내부 `core/`에 둔다(두 앱이 공유하지 않으므로 패키지로 승격할 필요 없음).
- **`packages/design_system`(`ondam_design_system`)**: 긴급 도움 플로팅 버튼 UI 등에 재사용할 공용 위젯, **`AppEmptyState`(확정 — 공통 컴포넌트로 구현 완료, 화면별 문구/아이콘/Action만 주입)**, `AppCard`, `AppTextField` 포함(Phase 1에서 골격 구현). `AppLoading`도 상황별(단순 로딩 vs 중요 작업 진행상태 텍스트 병행) variant를 지원하도록 확장 완료.
- **인증 관련 Interceptor**: `.claude/rules/api.md`에 따라 401 처리/로그아웃은 각 앱의 `auth` feature 책임, `packages/network`의 `ErrorInterceptor`는 매핑만 담당하는 기존 규칙을 그대로 따른다.
- **알림을 core/패키지가 아닌 feature로 둔 이유**: 검토 결과 `apps/guardian/lib/features/notification/`으로 확정 — 알림 수신 후 여러 feature 화면으로의 딥링크 오케스트레이션이 필요해 순수 core/패키지보다 feature 계층이 적합.

## 신규 요구사항 Architecture 반영 (v3)

> 아래는 구조만 정의한다. 실제 STT/TTS/AI 서비스, confidence 계산 로직, 관리자 시스템 구현은 하지 않는다. 관련 기술 미결정 사항은 `technical-decisions.md` §5 OPEN QUESTIONS 9~14에 정리했다.

### 음성 비서

```
Voice Input (마이크, apps/senior/lib/features/voice_assistant/presentation)
  ↓
STT (voice_assistant/data/datasources — 실제 서비스 미확정)
  ↓
Voice Intent 분석 / AI 처리 (voice_assistant/domain — 서버 Edge Function 경유 가능성 높음, §1-7과 동일한 "AI Key는 서버에만" 원칙 적용)
  ↓
Feature 호출 (voice_assistant가 같은 apps/senior 안의 document_scan / message_check / welfare_center / schedule 등 다른 feature의 UseCase를 호출 — 앱 경계를 넘지 않음)
  ↓
답변 생성
  ↓
TTS 음성 출력 (voice_assistant/presentation)
```

- `voice_assistant`는 다른 feature의 UseCase를 소비하는 쪽이며, 반대로 다른 feature가 `voice_assistant`를 참조하지 않는다(단방향 의존, `architecture.md`의 feature 결합 원칙과 동일).
- 온보딩에서 이미 확정된 음성 안내(TTS on/off, 읽기 속도) 설정을 재사용할 수 있는지는 `settings`와의 연동 지점으로 남겨둔다.

### 카메라(플래시 포함) — v8 구현 완료

```
Camera (apps/senior/lib/features/document_scan/presentation)
├── Capture(촬영)
├── Flash(ON/OFF/자동 — 상태가 화면에 항상 보이고, 쉬운 모드에서는 큰 버튼)
└── Image Processing(→ Backend 업로드, §1-8 즉시삭제 정책과 연결 — Phase 4 시점엔 백엔드 없음, 아래 "Camera Architecture" 참고)
```

- `document_scan` 내부 구조로 유지, 별도 feature로 분리하지 않는다(확정대로 구현). Android/iOS 모두 `camera`(공식 Flutter Favorite) + `permission_handler` 패키지로 구현 — Guardian 앱에는 추가하지 않음(Senior 전용).

### Camera Architecture (신규, v8)

`document_scan` feature 내부 구조:

```
document_scan/
├── domain/
│   ├── entities/       # CapturedPhoto, CameraFlashMode, CameraPermissionStatus — 순수 Dart
│   ├── repositories/    # CameraRepository(권한만), AnalysisRepository
│   └── usecases/
├── data/
│   ├── datasources/     # CameraPermissionDataSource(permission_handler 래핑)
│   └── repositories/    # CameraRepositoryImpl, AnalysisRepositoryImpl
└── presentation/
    ├── providers/        # cameraPermissionProvider, analysisNotifierProvider
    ├── pages/            # camera/preview/result 3화면
    └── widgets/
        └── camera_preview_view.dart   # package:camera를 직접 쓰는 유일한 파일
```

**핵심 설계 결정 — `CameraRepository`는 권한만 다루고, 카메라 하드웨어(프리뷰/플래시/셔터)는 다루지 않는다.**

- `CameraController`(package:camera)는 라이브 프리뷰 스트림을 그려야 하는 UI-bound, dispose가 필요한 컨트롤러 객체다 — `AnimationController`/`TextEditingController`와 성격이 같다. `flutter.md`가 이런 컨트롤러를 `StatefulWidget`의 로컬 상태로 두도록 명시하고 있어, `CameraPreviewView`(presentation/widgets) 안에 직접 둔다.
- 반면 "카메라 권한이 있는가"는 진짜 도메인/비즈니스 관심사(허용/거부/영구거부/제한에 따라 다른 화면 분기가 필요)라서 `CameraRepository`(권한 체크/요청 2개 메서드만)로 감싸고 UseCase/Provider를 거친다.
- 이 경계 덕분에 domain 계층은 `package:camera`/`package:permission_handler`를 전혀 모른다(architecture.md 의존 방향 규칙 준수) — 두 패키지를 import하는 파일은 `data/datasources/camera_permission_datasource.dart`와 `presentation/widgets/camera_preview_view.dart` 딱 2곳뿐이다.
- `AnalysisRepository`는 실제 AI 분석 백엔드(Storage 업로드 + Edge Function)가 아직 없어(§1-7/§1-8 설계는 확정, 구현은 아직) `analyzeDocument()`가 항상 `Err(UnavailableFailure())`를 반환한다 — 가짜 `AnalysisResult`를 만들지 않는다. `packages/core`의 `Failure` 계층에 `UnavailableFailure`(백엔드 없음)를 `ServerFailure`(백엔드가 있지만 실패함)와 구분해 신규 추가했다.
- Android는 `AndroidManifest.xml`에 `CAMERA` 권한 + `camera`/`camera.autofocus` feature(둘 다 `required=false`, 카메라 없는 기기에서도 설치 가능하게), iOS는 `Info.plist`에 `NSCameraUsageDescription` 추가.

### 어르신↔보호자 연결(QR) — v9 구현 완료

```
Senior: "보호자 연결" 화면 진입 → 서버에 단기 유효 연결 토큰 발급 요청 → QR로 렌더링
  ↓ (보호자가 화면을 보고 스캔)
Guardian: QR 스캔(카메라) → 토큰 파싱 → 서버로 토큰 전달(연결 요청 생성 호출)
  ↓
Backend: 토큰 유효성 + elder_id != guardian_id 검증 → guardian_links에 pending row 생성
  ↓
Senior: 연결 요청 확인 → 수락(accepted)/거절(rejected)
```

- `connection` feature 내부에 Senior는 "QR 생성/표시", Guardian은 "QR 스캔" 책임이 새로 추가된다. 두 앱 모두 기존에 `connection/` 디렉터리를 갖고 있었던 구조(위 Feature 매핑 참고)를 그대로 따른다 — 코드 공유는 하지 않는다.
- **Guardian 앱은 이전까지 카메라 기능이 없었다** — QR 스캔을 위해 Guardian 앱에 `mobile_scanner` + `permission_handler`를 신규 추가했다(Senior의 `document_scan`이 쓰는 `camera` 패키지와는 별개 — QR 스캔 전용).
- Senior 쪽 QR 생성은 카메라가 필요 없다 — 토큰 문자열을 `qr_flutter`로 QR 이미지 렌더링만 한다.
- QR에는 PII를 담지 않고 서버 발급 토큰 문자열만 담는다. 클라이언트(Guardian)는 토큰이 어떤 어르신을 가리키는지 알 필요가 없고, 스캔한 문자열을 그대로 서버로 전달만 한다 — `document_scan`의 `CameraRepository`와 유사하게, "QR 스캔(하드웨어 관심사)"과 "토큰 검증(도메인 관심사)"을 data/domain 경계로 분리했다.
- 데이터 모델: `connection_tokens` 테이블 + `create_connection_token`/`redeem_connection_token` SECURITY DEFINER 함수로 구현 완료(`technical-decisions.md` §1-6, §4).

### 답변 신뢰도 — v8: 표시 UI 구현 완료(원시 confidence→레벨 산정 로직은 미구현, OPEN QUESTIONS 11 유지)

```
AI / Analysis (analysis, message_check, document_scan 등에서 생성)
  ↓
Confidence / Reliability Metadata (analysis 도메인 엔티티에 필드로 저장 — 원시 점수)
  ↓
User-friendly Reliability UI (원시 점수를 그대로 노출하지 않고, "높음/보통/낮음" 등으로 변환하는 매핑 로직을 거쳐 표시)
```

- 원시 confidence 값 → 사용자 표현으로 변환하는 매핑 규칙은 `analysis` feature의 domain 또는 presentation 계층 중 어디에 둘지 구현 시 결정(로직 성격상 domain 권장, 순수 Dart로 테스트 가능해야 하므로) — **아직 미구현**: 실제 분석 백엔드가 없어 원시 점수 자체가 존재하지 않는다. `AppConfidenceIndicator`(design_system, Phase 3에서 구현)가 `ReliabilityLevel`을 받아 문장으로 렌더링하는 표시 로직만 v8에서 실제로 연결됐다(`document_scan_result_page.dart`).
- UI 표현 규칙은 `ui-spec.md` "신규 요구사항 UI 반영" 참고.

### 보호자 고지서 통계

```
Document Analysis (document_scan → analysis에 결과 저장)
  ↓
Structured Result (analysis 도메인 엔티티에 금액/기한/항목 등 구조화 필드)
  ↓
Backend (analysis_results 테이블, RLS로 보호자 접근 범위 제한)
  ↓
Guardian Statistics (guardian feature가 analysis의 통계 조회 UseCase를 통해 집계 표시)
```

- 보호자는 원본 문서(사진)에 접근하지 않는다(§1-8 원본 즉시삭제 정책과도 일치) — 구조화된 통계만 조회.
- 실제 통계 항목(월별 고지서/금액변화/이상변화 등)은 별도 Feature Spec에서 확정(`feature-spec.md` ADD/NEW-5 참고).

### 관리자 시스템 (PROPOSED, 미포함)

```
Senior App
Guardian App
      ↓
   Backend (Supabase)
      ↑
Admin System (future, 별도 앱/웹 — 미확정)
```

- 관리자 기능은 **일반 사용자용 어르신/보호자 Flutter 앱(`apps/senior`, `apps/guardian`)에 포함하지 않는다.**
- 다만 Backend(Supabase) 설계 시 관리자 접근을 완전히 배제하지 않도록, RLS 정책에 "관리자 역할(service role 또는 별도 admin role)"을 위한 여지를 남겨둔다 — 지금 당장 admin role을 만들지는 않되, 나중에 일반 사용자 role과 충돌 없이 추가할 수 있는 구조(예: `users.role` enum에 `admin` 값을 나중에 추가해도 기존 RLS 정책이 깨지지 않도록 설계)를 유지.
- 관리자 앱을 별도 Flutter 앱으로 만들지, 웹 관리자 페이지(Supabase Studio 확장 또는 별도 Admin Web)로 만들지, MVP에서 아예 제외할지는 `technical-decisions.md` OPEN QUESTIONS 13~14에서 다룬다.

## 확인이 더 필요한 설계 이슈 (v4 — 전부 해소)

- ~~위험 문자 감지 결과를 보호자에게 전달하는 실제 메커니즘~~ → **해소**: Push(FCM) + 서버 저장으로 확정(`technical-decisions.md` §1-4).
- ~~보호자-어르신 연결 인증 강도~~ → **해소**: 어르신 수락 방식으로 확정(§1-6).
- ~~보호자 앱과 어르신 앱이 하나의 Flutter 앱인지, 별도 앱인지~~ → **해소(Phase 1)**: **별도 2개 Flutter 앱 + Monorepo(공통 packages/*)로 확정.** 기존 웹 프로토타입의 `/`, `/guardian` 라우트 분기 구조는 채택하지 않는다. 이 결정에 따라 `apps/senior/`, `apps/guardian/`가 실제로 생성되었고, `technical-decisions.md` OPEN QUESTIONS 6번은 해결됨으로 종료 처리한다.
