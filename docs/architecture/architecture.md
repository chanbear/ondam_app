# Architecture (기능 반영)

> 저장소 전반의 아키텍처 규칙은 `.claude/rules/architecture.md`에 있다. 이 문서는 `feature-spec.md`, `docs/architecture/technical-decisions.md`(Architecture 결정 확정본)에서 도출된 기능들이 실제 저장소 구조에 어떻게 적재될지를 정리한다.
>
> **개정 이력**: v1은 Backend/DB/인증/연결 방식 등이 미확정인 상태의 "제안"이었다. v2에서 Backend(Supabase)/DB(PostgreSQL)/인증(OTP+PIN)/연결(어르신 수락)/알림(Push+서버) 등이 확정되었다. v3에서는 신규 요구사항(음성 비서/쉬운 모드 Main 강화/카메라 플래시/답변 신뢰도/보호자 고지서 통계 동기화/관리자 시스템 PROPOSED)을 반영했다. **v4(이 버전)**: Phase 1에서 "어르신 앱/보호자 앱을 하나의 Flutter 앱으로 만들지, 별도 앱으로 만들지" 결정이 **별도 2개 Flutter 앱(Monorepo)로 확정**되어, 아래 구조 전체를 `lib/features/` 단일 트리에서 `apps/senior/lib/features/` + `apps/guardian/lib/features/` + `packages/*` 구조로 갱신했다. 세부 실행 계획은 `docs/product/implementation-plan.md`를 참고.

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
| 인증(로그인/가입) | 어르신+보호자 각자 | `<app>/lib/features/auth/` | `ondam_network`, `ondam_storage`(Secure) | 전화번호+OTP(가입 1회)+PIN(평상시), 소셜 로그인. 양쪽 앱이 각자 구현(코드 공유 아님, Backend API 계약만 공유). Supabase Auth 결합 방식은 `technical-decisions.md` OPEN QUESTIONS 1번에서 구현 시 확정 |
| 온보딩(접근성/프로필/보호자 등록 요청) | 어르신+보호자 각자 | `<app>/lib/features/onboarding/` | `ondam_network`, `ondam_storage`(Local) | auth 이후 1회성 흐름. 보호자 등록은 "즉시 연결"이 아니라 `connection` feature의 요청 생성 UseCase를 호출 |
| 내 정보 | 어르신+보호자 각자 | `<app>/lib/features/profile/` | `ondam_network` | `onboarding`/`settings`와 데이터 소유 공유(같은 앱 내에서) |
| 홈(어르신, 일반/쉬운 모드) | 어르신 전용 | `apps/senior/lib/features/home/` | `ondam_design_system` | 쉬운 모드 상태는 `easyModeProvider`(`apps/senior/lib/core/easy_mode/`)로 앱 전역 `keepAlive` Provider 사용(확정, Phase 1에 기반 구현됨). 쉬운 모드가 홈의 Main UX로 격상되어, 일반 모드보다 쉬운 모드/음성 비서 진입 동선을 우선 설계해야 함 |
| 문서 촬영/AI 분석 | 어르신 전용 | `apps/senior/lib/features/document_scan/` | `ondam_network`, `ondam_models` | 분석 완료 후 원본 즉시 삭제(확정, `technical-decisions.md` §1-8). 카메라/이미지 피커 패키지는 실제 기능 착수 시 검토. 촬영 화면에 플래시 제어(ON/OFF/자동) 포함 — 별도 feature 아님, `document_scan/presentation/`의 촬영 위젯 책임 |
| 문자 내용 요약 | 어르신 전용 | `apps/senior/lib/features/message_check/` | `ondam_network`, `ondam_models` | **Android 전용**, `data/datasources/sms_datasource.dart`로 격리(확정, §1-9). iOS는 대안 UX(붙여넣기/공유/직접입력/기능제한) |
| 복지센터·경로당 찾기 | 어르신 전용 | `apps/senior/lib/features/welfare_center/` | `ondam_network`, `core/location`(앱 내 신규, 아직 없음) | 위치 기반 + 주소 검색 폴백 |
| 맞춤 정보(정보 탭) | 어르신 전용 | `apps/senior/lib/features/info/` | `ondam_network` | 나이 기반 개인화 |
| 분석 기록(`analysis`) | 어르신+보호자 **각자** | `apps/senior/lib/features/analysis/`(생성) + `apps/guardian/lib/features/analysis/`(조회) | `ondam_network`, `ondam_models`의 `AnalysisResult`/`ReliabilityLevel`/`RiskLevel` | 기존 `records`에서 개명. 문서/문자 분석 결과 통합, 고지서 통계 포함. `analysis_results` 테이블과 대응(§4). **두 앱이 같은 이름의 feature를 각자 갖되 코드는 공유하지 않는다** — 모양만 `packages/models`의 `AnalysisResult`로 통일하고, 실제 데이터는 Backend를 통해서만 오간다. `AnalysisResult`에 신뢰도(reliability) 메타데이터, 고지서 통계용 구조화 필드(`structuredFields`)가 이미 스켈레톤으로 존재(Phase 1) |
| 일정(`schedule`) | 어르신+보호자 각자 | `<app>/lib/features/schedule/` | `ondam_network` | `analysis`에서 분리(확정, `feature-spec.md` MODIFY-9). `schedules` 테이블과 대응. `Schedule` 공유 모델은 아직 `ondam_models`에 없음 — Phase 4(schedule 착수 시점)에 추가 |
| 어르신↔보호자 연결(`connection`) | **어르신+보호자 각자** | `apps/senior/lib/features/connection/` + `apps/guardian/lib/features/connection/` | `ondam_network`, `ondam_models`의 `GuardianLink`/`GuardianLinkStatus` | `guardian_links`(pending/accepted/rejected/revoked) 개념을 양쪽 앱이 공유 모델(`packages/models`)로만 공유하고 구현은 각자 한다. 어르신 측 "보호자 목록/해제" UI, 보호자 측 "연결 요청" UI 모두 이 feature가 담당. **v1~v3 문서에서는 Guardian App에만 있는 것처럼 서술된 부분이 있었는데, Senior App에도 반드시 필요하다 — Phase 1에서 두 앱 모두에 `connection/` 디렉터리를 생성해 이 불일치를 바로잡았다.** |
| 보호자(`guardian`) | 보호자 전용 | `apps/guardian/lib/features/guardian/` | `ondam_network`, `ondam_models` | 보호자 홈/받은연락/기록/통계. `connection`, `analysis`, `schedule`이 (Backend를 통해) 만들어내는 데이터를 조회만 함. Mock 프리뷰 화면은 만들지 않음(확정). "통계" 화면이 `analysis`가 제공하는 구조화된 고지서 통계를 조회해 표시(원본 문서 직접 노출 안 함) |
| 긴급 도움 | 어르신 전용(보호자 필요 여부는 확인 필요) | `apps/senior/lib/features/emergency_help/` | `ondam_design_system` | 로직(연락처 조회, tel: 링크)은 feature에 유지, UI 위젯만 `ondam_design_system`로 승격 |
| 알림(`notification`) | 보호자 전용(어르신 쪽 필요 여부는 위험 알림 외 확인 필요) | `apps/guardian/lib/features/notification/` | `ondam_network`, `ondam_storage`(FCM 토큰 캐시 등) | FCM 토큰 등록/수신/로컬표시/딥링크 담당. 발송 로직은 서버(Edge Function)에만 존재 |
| **음성 비서(`voice_assistant`)** | 어르신 전용 | `apps/senior/lib/features/voice_assistant/` | `ondam_network` | 음성 입력(STT)을 받아 의도를 분석하고, 다른 feature의 UseCase를 호출하거나 AI 응답을 받아 TTS로 출력. 다른 feature를 폭넓게 알아야 하는 오케스트레이션 성격이라 core/패키지가 아닌 독립 feature로 배치(§"신규 요구사항 Architecture 반영" 참고) |
| 설정(글자크기/음성/계정/언어/보호자정보/알림) | 어르신+보호자 각자 | `<app>/lib/features/settings/` | `ondam_network`, `ondam_storage`(Secure+Local 모두 사용) | 접근성 설정은 Local, 계정/토큰 관련은 Secure |
| 지원(`support`) | 어르신+보호자 각자 | `<app>/lib/features/support/` | `ondam_network` | 사용 방법 안내, 고객센터, 개인정보 보관 안내 |

### Feature 간 결합에 대한 메모

- `guardian`(App)은 `connection`, `analysis`, `schedule`이 Backend에 만들어낸 데이터를 조회만 한다. **같은 이름의 feature가 두 앱에 모두 있어도 코드를 공유하지 않는다** — 공유되는 것은 오직 `packages/models`의 타입 모양(`AnalysisResult`, `GuardianLink` 등)과 Backend API 계약뿐이다. `apps/guardian`이 `apps/senior`의 `lib/features/analysis/` 코드를 import하는 일은 없다(있다면 모노레포 원칙 위반).
- `emergency_help`의 "보호자에게 전화" 기능은 `connection`이 소유한 연결된 보호자 목록에서 연락처를 읽어야 한다(보호자 정보의 실제 source of truth는 `connection`의 `guardian_links`로 확정 — `settings`는 이를 표시/편집하는 화면만 제공).
- `message_check`가 감지한 위험 문자는 `analysis`에 저장되고, 어르신이 "보호자에게 알리기"를 누르면(Backend 경유로) 보호자 앱의 `notification`이 알림 이벤트를 수신한다. `message_check` → `analysis` → Backend → `notification` 순서.

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

### 카메라(플래시 포함)

```
Camera (apps/senior/lib/features/document_scan/presentation)
├── Capture(촬영)
├── Flash(ON/OFF/자동 — 상태가 화면에 항상 보이고, 쉬운 모드에서는 큰 버튼)
└── Image Processing(→ Backend 업로드, §1-8 즉시삭제 정책과 연결)
```

- `document_scan` 내부 구조로 유지, 별도 feature로 분리하지 않는다. Android/iOS 카메라 API 차이는 구현 Phase에서 확인.

### 답변 신뢰도

```
AI / Analysis (analysis, message_check, document_scan 등에서 생성)
  ↓
Confidence / Reliability Metadata (analysis 도메인 엔티티에 필드로 저장 — 원시 점수)
  ↓
User-friendly Reliability UI (원시 점수를 그대로 노출하지 않고, "높음/보통/낮음" 등으로 변환하는 매핑 로직을 거쳐 표시)
```

- 원시 confidence 값 → 사용자 표현으로 변환하는 매핑 규칙은 `analysis` feature의 domain 또는 presentation 계층 중 어디에 둘지 구현 시 결정(로직 성격상 domain 권장, 순수 Dart로 테스트 가능해야 하므로).
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
