# Implementation Plan — 온담 Flutter 구현 계획

> `feature-development` skill로 실제 기능 구현을 시작하기 **전** 단계 산출물이다. 이 문서 자체는 코드를 만들지 않는다.
>
> **개정 이력**
> - v1(초안): Architecture 미확정 상태를 전제로 한 계획.
> - v2: `docs/architecture/technical-decisions.md` v2에서 확정된 Backend(Supabase)/인증(OTP+PIN)/알림(Push+서버)/연결(어르신 수락)/위험판단(서버 AI)/저장(즉시삭제)/SMS(Android 격리)/Push(FCM)/Storage(Secure+Local 분리) 결정을 반영해 갱신.
> - v3: 신규 요구사항(음성 비서/쉬운 모드 Main 강화/카메라 플래시/답변 신뢰도/보호자 고지서 통계 동기화/관리자 시스템 PROPOSED)을 Feature 구조와 Phase 계획에 반영.
> - v4: Phase 1 실행 결과 반영. "하나의 앱, role 분기" 대신 **`apps/senior` + `apps/guardian` 별도 2개 Flutter 앱 + `packages/*` Monorepo**로 확정되어 Feature 구조를 두 앱으로 분리했다. Phase 1에서 실제로 스캐폴딩·구현된 부분은 아래에 "(Phase 1 완료)"로 표시했다.
> - v5: Phase 2 착수 전 Authentication Architecture(OTP+PIN+Session 결합, B안)를 확정하여 Phase 2를 더 이상 막는 미확정 사항이 없다. Phase 2 설명을 `technical-decisions.md` §1-3-A 설계에 맞춰 구체화했다.
> - v6: Authentication 세부 OPEN QUESTIONS(PIN 해시 알고리즘/Role 동시허용/idle timeout)를 실제 기술 조사로 확정. Phase 2를 pgcrypto/bcrypt, Role 동시허용 안내 UX, idle timeout 고정값(15분/5분)에 맞춰 갱신했다.
> - v7: **Phase 2(Authentication)를 실제로 구현 완료.** 두 앱(`apps/senior`, `apps/guardian`) 각자 전체 Auth feature(domain/data/presentation) + `core/auth/` + 라우터 redirect + idle timeout을 구현했고, DB migration 4개 + Edge Function 5개(`has-pin` 추가)를 작성했다. `dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug` 전부 통과. Supabase 프로젝트가 없어 실제 서버 통신은 미검증(NOT AVAILABLE). 상세는 아래 Phase 2 항목과 `technical-decisions.md` §1-3-A "Phase 2 구현 완료 요약".
> - v8: Phase 3(Senior/Guardian UI 골격) + Phase 4(문서 촬영 카메라/권한/플래시/미리보기/분석 요청 골격)를 구현 완료. 실제 AI 분석 백엔드는 여전히 없어 분석 요청은 항상 "준비 중" 상태로 귀결(가짜 결과 없음). `dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug` 양쪽 앱 전부 통과. 상세는 아래 Phase 3·4 항목.
> - v9: Phase 5 착수 전 미결정이었던 "보호자 연결 입력 방식"을 **QR 코드 기반**으로 확정(`technical-decisions.md` §1-6 v9, OPEN QUESTIONS 2번 DECIDED)하고, **Phase 5(Connection)를 실제로 구현 완료**했다. `connection_tokens` 테이블 + `create_connection_token`/`redeem_connection_token` DB 함수 + `guardian_links` write policy(전이 검증 트리거 포함) migration 3개, Edge Function 2개(`create-connection-token`/`redeem-connection-token`)를 작성했고, 두 앱(`apps/senior`, `apps/guardian`) 각자 전체 connection feature(domain/data/presentation)를 구현해 더보기 탭에 연결했다. `dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug` 양쪽 앱 전부 통과. Supabase 프로젝트가 없어 실제 서버 통신(토큰 발급/QR 스캔/RLS 적용)은 미검증(NOT AVAILABLE). 상세는 아래 Phase 5 항목.
> - v10: **Phase 6(Guardian 핵심 기능 + 고지서 통계 동기화)를 실제로 구현 완료.** `analysis_results` 테이블 migration(elder 본인 + `accepted` guardian_links 보유자만 SELECT, client INSERT/UPDATE/DELETE 정책 없음 — 쓰기는 미래의 서버 AI 파이프라인 전담)을 신규 작성했다. Guardian 앱에 `analysis` feature(domain/data/presentation)를 신규 구현해 홈(안심 상태/최근 활동)·알림(받은 연락)·기록·통계 탭을 전부 실제 데이터 조회로 연결했고, `connectedEldersProvider`를 Phase 5의 실제 `guardian_links`(accepted만) 기반으로 교체했다. **OPEN QUESTIONS #12(고지서 통계 최종 데이터 항목)는 여전히 미결정**이라 통계 탭은 스키마와 무관하게 항상 well-defined한 두 집계(이번 달 분석 건수/위험 문자 건수)만 `AppStatCard`로 보여주고, 고지서 구조화 필드는 기록별 원본을 제네릭하게(key-value) 나열하는 데 그쳤다 — 차트 라이브러리도 여전히 추가하지 않았다(Decision 3 유지). `dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug` 양쪽 앱 전부 통과, packages는 `dart analyze` 전부 통과(`dart test`는 대상 테스트 파일 자체가 없어 N/A). `analysis_results`가 실제로는 항상 빈 테이블(Phase 4 AI 분석 백엔드 부재)이라 모든 신규 화면이 정직하게 Empty State로 귀결된다 — 가짜 데이터 없음. 상세는 아래 Phase 6 항목.
>
> - v11: **Phase 7(위험 문자 확인, `message_check`)을 실제로 구현 완료.** Android는 `flutter_sms_inbox` 기반 실제 SMS inbox 자동 조회(권한 granted/denied/permanentlyDenied 3상태 처리), iOS는 자동 접근 없이 클립보드 붙여넣기+직접 입력으로 구현했다(`technical-decisions.md` §1-9/§5 OPEN QUESTIONS #4 DECIDED, v11). 위험도 분석은 `document_scan`과 동일하게 아직 없는 백엔드를 향해 항상 `UnavailableFailure`를 반환한다(가짜 분석 결과 없음) — `AnalysisResultView`를 `document_scan`에서 `apps/senior/lib/core/widgets/`로 승격해 두 feature가 공유하도록 리팩터링했다. Guardian 앱은 Phase 6에서 이미 `AnalysisType.message`를 분기 처리하고 있어 신규 feature나 코드 변경 없이 그대로 동작한다(코드 확인 완료, `guardian` 전용 feature 미생성). Senior 앱 신규 테스트 37개(기존 79개 + 37개), `dart format`/`flutter analyze`/`flutter test` 양쪽 앱 통과. Supabase/Edge Function 변경 없음(기존 `analysis_results` RLS가 `type` 무관하게 이미 커버). 실기기 SMS 하드웨어 동작은 이 환경에 Android 실기기/에뮬레이터가 없어 **NOT AVAILABLE**. 상세는 아래 Phase 7 항목.
> - v12: Phase 8(알림) **Backend 인프라만** 구현(`notifications`/`fcm_tokens` migration, `send-notification` Edge Function) — Guardian 클라이언트는 아직 없었다. 상세는 `technical-decisions.md` v12, 아래 Phase 8 항목.
> - v13: Phase 8 Guardian 클라이언트(FCM lifecycle/알림 목록/딥링크)를 구현 완료하고, 통합 검증에서 찾은 두 silent-failure(알림 읽음 처리, 로그아웃 토큰 삭제가 RLS에 막혀 조용히 no-op)를 RPC/정책 추가(migration `20260814000004`)로 수정했다. **가장 중요한 변경: Phase 7 AI 위험분석을 실제로 구현했다** — `analyze-message` Edge Function(Anthropic Claude, `ANTHROPIC_API_KEY`)을 신규 작성해 `MessageRiskRepositoryImpl`이 항상 `UnavailableFailure`이던 것을 실제 호출로 교체했고, 위험 판정 시 서버가 직접 `guardian_links`(accepted)를 조회해 대상 보호자를 정해 `send-notification`을 호출하도록 연결했다(client가 임의 대상을 지정할 수 없음). 이 과정에서 `send-notification`의 실제 버그(FCM `data`에 `elder_id`/`analysis_result_id` 누락 — 푸시 탭 딥링크가 항상 조용히 실패)를 발견해 함께 수정했다. Senior/Guardian `dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug` 전부 통과(Senior 신규 repository 테스트 6개, 기존 위젯 테스트 2개는 실제 Supabase 의존이 생겨 Fake repository override로 조정 — 삭제/약화 아님, 동일 assertion 유지). Deno 테스트 파일도 작성했으나 이 환경에 Deno CLI가 없어 **미실행**. 실제 Supabase 연결(CLI/Docker/credentials 전부 없음)/실제 AI 호출/실제 FCM 발송/실기기 E2E는 전부 **NOT AVAILABLE** — "위험 문자 발생 시 보호자에게 실제 Push 도달"은 여전히 미검증. 상세는 아래 Phase 8 항목.
> - v14: Phase 4(`document_scan`)의 AI 분석 백엔드 실제 연결 코드(v13 `analyze-message`와 동일 패턴)가 이전 세션에 이미 작성돼 커밋되지 않은 채 working tree에 남아 있었음을 확인하고, 이번 세션에는 그 코드를 실행 검증(`dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug`)하고 이 문서에 v14로 문서화했다 — `git log --follow`상 `analysis_remote_datasource.dart`/`analyze-document/`/migration 파일은 커밋 이력이 없고(신규 미커밋), `analysis_repository_impl.dart`는 v8 커밋(`55fa319`) 이후 미커밋 수정 상태였다(코드 작성 자체는 이번 세션 산출물이 아님). v8에서 골격만 만들고 항상 `UnavailableFailure`로 남겨뒀던 마지막 지점이 이 코드로 연결되어 있다. `analyze-document` Edge Function(Anthropic Claude Messages API, vision 입력 + tool-forced 구조화 출력)을 신규 작성하고, `document-photos` private Storage 버킷(migration `20260814000006`, 본인 폴더에만 INSERT 가능·client SELECT/UPDATE/DELETE 정책 없음)을 추가했다. 클라이언트는 본인 JWT로 사진을 업로드한 뒤 저장 경로만 Edge Function에 전달하고, Edge Function은 service role로 다운로드해 분석한 뒤 성공/실패와 무관하게 `finally`에서 원본을 즉시 삭제한다(§1-8 "원본 즉시 삭제"가 이제 실제로 검증 가능한 코드로 존재). `AnalysisRepositoryImpl`은 `analyze-message`와 동일한 reason-code → `Failure` 매핑을 따른다. 기존 위젯 테스트 2개(`document_scan_preview_page_test.dart`/`document_scan_result_page_test.dart`)는 실제 Supabase 의존이 생겨 `FakeAnalysisRepository` override로 조정했다(assertion은 그대로 유지). Senior 신규 repository 테스트 8개 포함 `document_scan` 스위트 27개, Senior 앱 전체 `flutter test` 122개 통과, `dart format`/`flutter analyze` 통과(analyze의 기존 2건 info는 이번 변경과 무관한 `auth` feature). AI provider 시크릿은 `analyze-message`와 동일한 `ANTHROPIC_API_KEY`를 재사용(신규 키 없음). 이 환경에는 값이 없어 실제 AI 호출/실제 Storage 업로드/실제 Supabase 연결은 여전히 **NOT AVAILABLE**(Deno 테스트 파일도 작성했으나 Deno CLI가 없어 미실행). Guardian 앱은 변경 없음(이미 Phase 6에서 `AnalysisType.document`를 처리 중이었음을 코드로 재확인). 상세는 아래 Phase 4 항목.
> - v15: **Phase 9(UI 개선)를 구현 완료.** 착수 전 코드 조사에서 "답변 신뢰도 UI" 항목은 Phase 4/7에서 `AppConfidenceIndicator`/`AnalysisResultView`로 이미 구현 완료돼 있음을 확인해 재작업하지 않았다. 남은 3개 항목을 사용자 확인(AskUserQuestion) 후 구현했다: (1) **긴급 도움 실제 전화 연결** — `url_launcher` 패키지를 신규 추가하고 `emergency_help/domain`(`DialerRepository`/`CallPhoneUseCase`)·`data`(`DialerRepositoryImpl`)를 구현해 119/112/118은 실제 다이얼러로 연결한다. "보호자에게 전화"는 보호자 전화번호를 조회할 데이터 소스가 이 저장소에 아직 없어(`guardian_links`는 `guardian_id`만 가짐, 전화번호를 노출하는 `users`/profile 테이블 부재) 가짜 번호로 연결을 시도하는 대신 정직한 안내("보호자 전화번호를 아직 알 수 없어요")로 남겼다. (2) **지원(고객 지원) 화면 신규 구현** — `support` feature가 완전히 비어 있었던 것을 확인하고 `SupportPage`/`PrivacyInfoPage`를 신규 구현했다. 실제 고객센터 연락처(전화/이메일)는 이 저장소에 사업 정보가 없어 사용자 선택에 따라 정직한 준비중 안내로 남겼고, 개인정보 보관 안내는 이 저장소에서 실제로 확정·구현된 정책(§1-3-A PIN 미저장/§1-8 원본 즉시삭제/§2-3 accepted guardian만 조회/회원탈퇴 즉시삭제)만 서술했다 — 분석 결과 원문 보관 기간처럼 미확정인 항목(§5 OPEN QUESTIONS 5번)은 확정된 것처럼 지어내지 않고 "아직 정해지지 않았다"고 그대로 안내한다. `MoreTabPage`의 "고객 지원"을 `ComingSoonPage`에서 `SupportPage`로 교체했다. (3) **쉬운 모드 하단 Navigation** — OPEN QUESTIONS 8번을 "탭 구성은 유지하고 스타일(아이콘/라벨 크기)만 확대"로 DECIDED 처리하고, `design_system`에 `AppEasyMode` 토큰(`navIconScale`/`navBarHeight`)을 추가해 `AppBottomNavigation`에 `large` 파라미터로 반영했다. `HomeShellPage`가 `easyModeProvider`를 watch해 `large: easyMode`로 전달한다(Guardian 앱은 영향 없음, 기본값 `false`). **접근성 재검수**에서 기존 위젯(`AppIconButton`/`FlashToggleButton`/`HomeFeatureLargeButton`/`_ShutterButton`/`_BackLink`)은 이미 Semantics/44~48px 터치 영역을 준수하고 있음을 확인했고, 긴급 도움 `FloatingActionButton`에 누락돼 있던 `tooltip: '긴급 도움'`을 추가했다. **테스트 중 실제 버그 발견**: `EmergencyHelpSheet`에 처음 작성한 widget test가 `RenderFlex overflowed` 오류로 실패해, 이 화면이 (테스트가 없어 지금까지 발견되지 못한 채) 작은 화면/모달 시트 높이에서 실제로 넘침을 확인 — `SingleChildScrollView`로 감싸 수정했다. Senior 앱 신규 테스트 8개(`CallPhoneUseCase` 3, `EmergencyHelpSheet` 3, `SupportPage` 2) + `design_system` 신규 2개(`AppBottomNavigation` large 모드) 포함 Senior `flutter test` 130개, `design_system flutter test` 2개 전부 통과. `dart format`/`flutter analyze`(Senior/`design_system` 모두 0 issue, Senior의 기존 info 2건은 이번 변경과 무관한 `auth` feature)/`flutter build apk --debug` 통과. Guardian 앱은 이번 Phase 대상이 아니라 변경 없음. 상세는 아래 Phase 9 항목.
> - v16: **Phase 10(음성 비서)을 구현 완료.** 착수 전 이 Phase를 막고 있던 OPEN QUESTIONS 9~10(STT/TTS 서비스, 의도분류 방식)을 사용자 확인(AskUserQuestion) 후 DECIDED 처리했다 — (9) 온디바이스 `speech_to_text`/`flutter_tts`(클라우드 서비스 아님, 추가 비용/음성 데이터 외부전송 없음), (10) 클라이언트 키워드 매칭(서버 AI 호출 없음). 예시로 들었던 "경로당 찾아줘" 명령은 `welfare_center` feature 자체가 완전히 비어 있어(`.gitkeep`만 존재) 이번 범위에서 제외하고, 실제 존재하는 기능 3개(문서 촬영/문자 확인/긴급 도움)만 연결하기로 함께 확인했다. `apps/senior/lib/features/voice_assistant/`를 신규 구현: domain(`VoiceIntent`/`ClassifyVoiceIntentUseCase` — 순수 키워드 매칭, 서버 호출 없음 / `MicPermissionStatus`/`MicRepository`/`CheckMicPermissionUseCase`/`RequestMicPermissionUseCase` — `document_scan`의 `CameraPermissionStatus`/`CameraRepository` 구조를 그대로 미러링), data(`MicPermissionDataSource`/`MicRepositoryImpl`, `permission_handler`의 `Permission.microphone` 래핑), presentation(`VoiceAssistantPage` — 마이크 권한 상태별 분기, `document_scan_camera_page.dart`와 동일 구조 / `VoiceInteractionView` — `SpeechToText`/`FlutterTts` 엔진을 직접 소유하는 `ConsumerStatefulWidget`, `CameraPreviewView`가 `CameraController`를 직접 소유하는 것과 동일한 이유). ui-spec.md "음성 비서 상태" 표(진입/듣는 중/처리 중/답변/인식실패)를 그대로 상태 UI로 구현했고, 인식 실패·무음은 하드 에러가 아니라 "다시 한번 말씀해주세요" 부드러운 재시도로 처리한다(ui-spec.md 원칙 그대로). Home 탭의 "음성 비서" 카드를 `ComingSoonPage`에서 `VoiceAssistantPage`로 교체했다. `speech_to_text ^7.4.0`/`flutter_tts ^4.2.5` 신규 추가, Android `RECORD_AUDIO` 권한과 iOS `NSMicrophoneUsageDescription`/`NSSpeechRecognitionUsageDescription`을 추가했다. Senior 신규 테스트 9개(`ClassifyVoiceIntentUseCase` 5, mic permission usecase 4) — `flutter test` 130→139개 전부 통과. `VoiceAssistantPage`/`VoiceInteractionView` 자체는 플랫폼 채널(STT/TTS 엔진)에 의존해 `document_scan_camera_page`/`CameraPreviewView`가 이 저장소에서 위젯 테스트 없이 남아있는 것과 동일한 이유로 위젯 테스트를 작성하지 않았다(선례와 일관). `dart format`/`flutter analyze`(0 issue, 기존 info 2건은 무관한 `auth` feature)/`flutter build apk --debug` 통과 — 단 빌드 로그에 `flutter_tts`/`speech_to_text`가 Kotlin Gradle Plugin(KGP)을 구버전 방식으로 적용한다는 비차단 경고가 있어 향후 Flutter 업그레이드 시 재확인이 필요하다(§5 신규 OPEN QUESTIONS로 남기지 않음 — 빌드는 여전히 성공하므로 차단 사유 아님, 다음 Flutter SDK 업그레이드 시점에 재검토). 실제 한국어 STT 인식 정확도/TTS 발화/마이크 권한 실기기 동작은 이 환경에 Android/iOS 실기기가 없어 **NOT AVAILABLE**(코드 수준 검증까지만 완료). Guardian 앱은 이번 Phase 대상이 아니라 변경 없음. 상세는 아래 Phase 10 항목.
> - **v17(이 버전)**: **Phase 11(통합 테스트 및 안정화)을 구현 완료** — 계획된 11개 Phase 전체가 완료됐다. 안정화 점검에서 실제 버그를 발견해 수정했다: Senior/Guardian 양쪽 `PinNotifier.deleteAccount()`가 성공 후 `signOutUseCase`를 호출하지 않고 있었다 — 계정은 서버에서 이미 삭제됐지만 로컬 Supabase 세션이 남아 라우터의 `hasSession` 게이트가 삭제된 계정을 PIN 입력 화면으로 보낼 수 있는 상태였다. 같은 점검에서 `TextStyle(color: AppColors.error)` 하드코딩 4건(양쪽 `settings_page.dart`/Senior `guardian_list_page.dart`/Guardian `connection_list_page.dart`)을 `AppTextStyles.xxx.copyWith(color:)`로 교체했다(ui-design.md 규칙 위반이던 기존 코드). 계정 탈퇴 정책(§2 item 10) 정적 검증에서는 모든 사용자 소유 테이블에 `on delete cascade`가 실제로 걸려 있어 "본인 데이터 즉시 삭제"는 보장됨을 확인했지만, "보호자 쪽에 연결 종료 안내를 남긴다"는 부분은 cascade가 레코드 자체를 지워 구현돼 있지 않음을 발견 — 이번에 임의로 설계하지 않고 신규 OPEN QUESTIONS 24번으로 남겼다. `test/integration/`을 양쪽 앱에 신규 도입해 계정 탈퇴 흐름(방금 고친 버그의 회귀 테스트, 2세트)과 보호자 연결 수락/거절/해제 흐름(지금까지 domain usecase 단위 테스트만 있던 gap, 2세트)을 작성했다. go_router의 `hasSession` 게이트가 `Supabase.instance.client.auth.currentSession`을 직접 읽어 fake로 override할 수 없음을 확인해, OTP+PIN 가입 전체를 관통하는 진짜 end-to-end 라우터 테스트는 이 환경에서 구조적으로 NOT AVAILABLE임을 문서화했다 — 대신 인증 화면을 우회해 대상 화면을 직접 마운트하는 기존 프로젝트 관례를 그대로 따랐다. Senior `flutter test` 139→144개, Guardian 100→105개 모두 통과, `dart format`/`flutter analyze`(양쪽 0 issue)/`flutter build apk --debug`(양쪽 성공) 통과. "보호자 연결요청→위험문자→Push알림"의 실제 크로스앱 E2E와 음성 비서 실기기 동작은 실 Supabase/FCM/AI 키/실기기가 없어 지금까지와 동일하게 **NOT AVAILABLE**로 남는다. 상세는 아래 Phase 11 항목.
>
> 기반 문서: `docs/product/current-app-analysis.md`, `docs/product/feature-spec.md`, `docs/product/user-flow.md`, `docs/architecture/architecture.md`, `docs/ui/ui-spec.md`, `docs/architecture/technical-decisions.md`

---

## 1. Flutter Feature 구조 최종 제안 (v4 — 2개 앱 + 공통 패키지)

```
apps/senior/lib/features/
├── auth/                 # 전화번호+OTP(가입)+PIN(로그인), 소셜 로그인
├── onboarding/            # 접근성 설정 → 프로필 입력 → 보호자 등록 요청(최초 1회 흐름)
├── profile/               # 내 정보 조회/수정
├── home/                  # 어르신 홈(쉬운 모드가 Main UX, 일반 모드 병행), 오늘 할 일 요약
├── document_scan/         # 문서 촬영(플래시 제어 포함) → AI 분석 → 결과 표시 (원본 즉시삭제 정책 반영)
├── message_check/         # 수상한 문자 확인 (Android 전용, sms_datasource로 격리)
├── analysis/              # 분석 기록(문서+문자 결과), 고지서 통계 생성(구조화 필드+신뢰도 메타데이터 포함)
├── schedule/               # 일정(할 일) 관리
├── welfare_center/        # 주변 경로당·복지센터 찾기
├── info/                  # 나이 기반 맞춤 정보
├── connection/             # 어르신 측: 보호자 목록 확인/연결 요청 수락·거절/해제
├── voice_assistant/       # 음성 입력(STT) → 의도분석/AI → 기능 호출 → 음성 출력(TTS)
├── emergency_help/        # 긴급 도움(보호자/119/112/118 연결)
├── settings/               # 글자크기/음성/언어/계정/보호자 정보/알림 설정
└── support/                # 사용 방법 안내, 고객센터, 개인정보 보관 안내

apps/guardian/lib/features/
├── auth/                 # (Senior와 별도 구현, 동일 Backend 계약)
├── onboarding/
├── profile/
├── home/                  # 보호자 홈 — 연결된 어르신 요약, 안심 상태
├── connection/             # 보호자 측: 연결 요청 생성
├── guardian/                # 받은 연락, 분석 기록 조회, 고지서 통계 조회
├── analysis/              # Senior가 만든 분석 데이터를 Backend를 통해 조회하는 뷰
├── schedule/               # 다가오는 일정 조회
├── notification/          # FCM 토큰 등록/수신/로컬 표시/딥링크
├── settings/
└── support/
```

> **관리자 시스템은 이 목록에 포함하지 않는다.** PROPOSED 상태이며, 포함 여부·형태가 결정되지 않아 일반 사용자용 어르신/보호자 앱 feature 구조와 분리해 별도로 검토한다(`architecture.md` "관리자 시스템(PROPOSED, 미포함)" 참고).

```
packages/
├── core/            # Failure — 프레임워크 비의존, pure Dart (Phase 1 완료)
├── design_system/    # AppColors/AppTextStyles/AppSpacing/AppRadius/AppTheme + AppButton/AppCard/AppEmptyState/AppError/AppLoading/AppTextField (Phase 1 완료)
├── models/           # AnalysisResult/AnalysisType/ReliabilityLevel/RiskLevel/GuardianLink/GuardianLinkStatus 스켈레톤 (Phase 1 완료)
├── network/           # DioClient(baseUrl 파라미터화)/NetworkException/ErrorInterceptor, pure Dart (Phase 1 완료)
├── storage/           # SecureStorageService(flutter_secure_storage)/LocalStorageService(shared_preferences) (Phase 1 완료)
└── shared/            # 아직 비어있음 — 실제 공통 유틸 필요해질 때 채운다
```

각 앱의 `core/`(패키지 아님, 앱 내부)에는 다음이 추가된다: `core/network/network_providers.dart`(Phase 1 완료 — `ondam_network`의 `DioClient`에 각 앱의 `AppConfig.apiBaseUrl`을 주입하는 얇은 wiring), `core/storage/storage_providers.dart`(Phase 1 완료 — `ondam_storage`의 두 서비스를 Riverpod Provider로 노출), 그리고 Senior 앱에는 `core/easy_mode/easy_mode_provider.dart`(Phase 1 완료 — §2 참고)가 추가된다. `notification`은 core가 아닌 Guardian 앱의 독립 feature로 확정(알림 수신 후 여러 feature로의 딥링크 오케스트레이션이 필요해 순수 core보다 feature 계층이 적합, `architecture.md` 원칙에 부합).

### 변경 이력 (v3 → v4)

- **가장 큰 변경**: `lib/features/` 단일 트리 전제를 폐기하고 `apps/senior/lib/features/` + `apps/guardian/lib/features/`로 분리. 두 앱 사이의 "공유"는 코드 공유가 아니라 `packages/models`의 타입 모양 공유 + Backend API 계약 공유로 이루어진다.
- **`connection` feature가 사실은 두 앱 모두에 필요하다는 점을 바로잡음**: v1~v3 문서는 이 feature를 마치 어르신 앱에는 없고 보호자 앱 전용인 것처럼 다루는 서술이 섞여 있었다. 실제로는 어르신 쪽(보호자 목록 확인/해제, 요청 수락)과 보호자 쪽(요청 생성) 모두 필요하며, Phase 1에서 두 앱 모두에 `connection/` 디렉터리를 만들어 반영했다.
- `connection`: `technical-decisions.md` §1-6(어르신 수락 방식) 확정으로 **요청(pending) → 어르신 확인 → 수락/거절** 상태 흐름을 갖는 것으로 구체화(변경 없음, v2에서 이미 반영).
- `notification`: Guardian 앱 전용 feature로 확정(Push(FCM) 수신은 보호자 쪽에서만 필요 — 어르신 쪽 "위험 알림 보내기"는 `message_check`/`analysis`가 Backend에 이벤트를 남기는 것으로 끝나고, 실제 Push 수신·표시는 보호자 앱 책임).
- `message_check`: `technical-decisions.md` §1-9의 정확한 디렉터리 구조(`data/datasources/sms_datasource.dart`)를 Phase 1에서 실제로 반영(Android 전용 DataSource 자리, 구현은 Phase 7).

### 각 Feature가 필요한 이유

- **auth**: 전화번호+OTP(가입 1회)+PIN(평상시) 흐름을 모두 이 feature가 책임진다. `technical-decisions.md` §1-3, §2-1/§2-2(OPEN QUESTIONS 포함)와 직접 연결.
- **onboarding**: 최초 1회 흐름을 홈/설정과 분리. 보호자 등록은 이제 "즉시 등록"이 아니라 "연결 요청 생성"이므로, 실제 연결 성사 로직은 `connection`에 위임하고 onboarding은 입력 UI만 담당.
- **profile**: `settings`의 "내 정보"와 데이터 소유를 공유.
- **home**: 어르신 앱 진입점, 쉬운 모드 전환 지점.
- **document_scan / message_check**: 입력 소스와 플랫폼 제약이 달라 분리 유지. 결과는 `analysis`에 기록. **v3**: `document_scan`의 촬영 화면은 플래시 ON/OFF/자동 상태를 항상 명확히 보여주고 쉬운 모드에서는 큰 버튼으로 제공(별도 feature로 분리하지 않음 — 카메라 캡처와 강하게 결합된 UI 상태이기 때문).
- **analysis**: 문서/문자 분석 결과와 고지서 통계 통합. `technical-decisions.md` §4의 `analysis_results` 테이블과 1:1 대응. **v3**: 신뢰도(reliability) 메타데이터와 고지서 통계용 구조화 필드(`structured_fields`)를 이 feature의 도메인 엔티티가 소유 — 문서 분석이든 문자 분석이든 결과가 나오는 지점이 하나이므로, 신뢰도 변환 로직과 통계 집계 로직을 여기 한 곳에서 관리해 `guardian`/`voice_assistant` 등 소비자가 중복 구현하지 않게 한다.
- **schedule**: 어르신 "기록 탭 - 일정"과 보호자 "다가오는 일정"의 공통 데이터 소유.
- **welfare_center / info**: 기존과 동일한 이유로 유지.
- **connection (양쪽 앱 모두에 존재)**: `guardian_links`(pending/accepted/rejected/revoked) 개념을 다루는 feature. 어르신 앱의 `connection`은 "보호자 목록 확인/요청 수락·거절/해제" UseCase를, 보호자 앱의 `connection`은 "연결 요청 생성" UseCase를 갖는다 — 코드는 공유하지 않고 `packages/models`의 `GuardianLink` 모양과 Backend API만 공유한다.
- **guardian (보호자 앱 전용)**: `analysis`, `schedule`을 Backend를 통해 조회만 한다. "통계" 화면에서 고지서 통계(구조화 필드 기반)를 조회 — 원본 문서 이미지는 조회하지 않는다(§1-8 원본 즉시삭제 정책과 일치).
- **emergency_help**: 상시 노출 로직, 독립 유지. **v3**: 쉬운 모드 Main에서 `home`/`voice_assistant`와 함께 "가장 자주 쓰는 기능" 동선에 포함되므로, `home`이 이 feature의 진입점을 최소 탭으로 노출해야 한다(§2 참고).
- **notification (보호자 앱 전용)**: FCM 토큰 등록·갱신, Push 수신 시 로컬 알림 표시, 알림 탭 시 올바른 화면으로 이동(딥링크)까지 책임진다. 발송(서버→FCM)은 Backend 책임이라 이 feature는 수신 측만 다룬다.
- **voice_assistant (v3 신규)**: 음성 입력을 받아 다른 feature의 UseCase를 호출하는 오케스트레이션 책임을 가진다. 여러 feature를 폭넓게 알아야 하므로 `core`가 아닌 독립 feature로 두고, 다른 feature는 `voice_assistant`를 참조하지 않는 단방향 의존을 유지한다(`architecture.md` "신규 요구사항 Architecture 반영" 참고).
- **settings**: 접근성 설정(Local Storage), 계정(Secure Storage 연동), 알림 채널 on/off.
- **support**: 정적 콘텐츠 + 문의 채널.

---

## 2. 쉬운 모드 상세 설계 (확정, v3: Main UX로 격상)

`technical-decisions.md` UI 결정 A에 따라 **다음은 모두 확정 사항**이다(v1에서는 "검토"로 표현했던 항목들도 이번에 확정으로 승격).

> **v3 갱신**: 쉬운 모드는 더 이상 "설정에서 켜고 끄는 옵션"이 아니라 **어르신용 앱의 핵심 Main UX**로 취급한다. 홈 화면에서는 (1) 쉬운 모드 Main, (2) 큰 버튼, (3) 핵심 기능 중심 Navigation, (4) 음성 비서, (5) 긴급 도움, (6) 직관적인 안내가 하나의 경험으로 자연스럽게 연결되어야 한다. 특히 홈 화면은 어르신이 가장 자주 쓰는 기능(문서 촬영/문자 확인/경로당 찾기/음성 비서/긴급 도움)을 **최소한의 선택(탭 1~2회)**으로 접근할 수 있게 설계한다. 실제 Main 화면 구조는 Phase 3(골격)과 Phase 9(완성)에서 구체화하며, 이 문서는 방향만 정의한다 — 화면 와이어프레임/코드는 아직 만들지 않는다.

| 항목 | 확정 내용 |
|---|---|
| **활성화 방식** | 홈 화면 상단 토글, 즉시 전환 |
| **일반 모드와의 차이** | 단순 글자 확대가 아니라 **버튼 크기 / 정보량 / Navigation / 화면 복잡도 / 텍스트 / 여백 / 주요 기능 우선순위**까지 바뀌는 별도 UX 모드 |
| **적용 범위** | **전체 앱**(하단 Navigation 포함, 구성 자체를 바꿀 수 있음 — 세부 범위는 `technical-decisions.md` OPEN QUESTIONS 8번) |
| **글자 크기 설정과의 관계** | **독립적인 설정**으로 유지(쉬운 모드 on + 글자 크기 "아주 크게" 조합 가능) |
| **상태 저장** | Local Storage(`core/storage`)에 영속화 |
| **앱 재실행 후 유지 여부** | **유지** |
| **정보량** | 보조 설명/부가 링크를 생략하고 핵심 행동 문구만 남김(v1 설계 유지) |
| **색상** | 팔레트는 일반 모드와 동일, 배경 대비만 강화 검토(v1 설계 유지) |
| **긴급 도움 노출 위치** | 플로팅 버튼 대신 하단 Navigation에 통합(기존 앱 관찰 기반 KEEP) |

### Flutter 구현 구조

- `easyModeProvider`: `core` 레벨 `keepAlive` Provider, Local Storage와 동기화.
- `home` feature 내부에 `HomeNormalView` / `HomeEasyView` 두 위젯, 상위에서 Provider 값으로 분기 렌더링.
- 하단 Navigation은 `app/router` 또는 `core/widgets`의 공용 셸(Shell) 위젯이 `easyModeProvider`를 구독해 두 가지 레이아웃(일반 탭바 vs 확대 탭바+통합 도움 버튼) 중 하나를 렌더링.
- 테마 레이어: `AppSpacing`/`AppTextStyles`를 완전히 새로 만들지 않고, 쉬운 모드 배율 헬퍼(예: `AppSpacing.md * kEasyModeScale`)를 우선 검토.
- 테스트: 두 모드 각각에서 동일 UseCase가 호출되는지 Widget Test로 검증(비즈니스 로직 동일성 보장).

---

## 3. Android / iOS 플랫폼 차이 (확정 반영)

`technical-decisions.md` §1-9와 동일한 방향을 재확인.

| 항목 | Android | iOS | 구분 |
|---|---|---|---|
| SMS 읽기 | `message_check/data/datasources/sms_datasource.dart`(Android 전용)로 구현 | **직접 읽기 시도하지 않음**(확정) | iOS는 붙여넣기/공유/직접입력/기능제한 중 구현 시점에 선택 |
| Push 알림(FCM) | 지원 | 지원(APNs 경유) | 구현 가능 |
| Background 실행 | 제한적, SMS 브로드캐스트 리시버 등으로 특정 이벤트 트리거 가능 | 매우 제한적 | "새 문자 도착 즉시 자동 분석"은 Android 전용 |
| 위치 권한 | Foreground 권한으로 충분(`welfare_center`) | Foreground 권한으로 충분 | 구현 가능 |
| 카메라/사진 접근 | 런타임 권한 | 런타임 권한(세분화 접근 가능) | 구현 가능 |
| 긴급 전화 연결 | 다이얼러 호출 | 다이얼러 호출 | 구현 가능 |

### 구현 가능한 것 vs 플랫폼 제약

- **양 플랫폼 구현 가능**: Push/로컬 알림, 위치 검색, 사진 업로드 분석, 긴급 전화, SMS 작성화면 열기(발송은 사용자 직접).
- **Android 전용**: 수신 문자함 직접 읽기 기반 위험 문자 자동 확인.
- **양쪽 제한적**: 백그라운드 자동 문자 감지 — 기본 흐름은 "사용자가 앱을 열어 확인"으로 설계하고, 완전 자동화는 로드맵 후순위.

---

## 4. UI 개발 계획 (확정 반영)

1. **Design Token 정합화** — `AppColors` placeholder 확정 + `technical-decisions.md` UI-B에 따라 `emergency` 토큰 신설 여부/값 결정(색상값은 `technical-decisions.md` OPEN QUESTIONS 7번).
2. **Typography 확정**.
3. **공통 컴포넌트 우선 구축** — `AppButton`, `AppLoading`(단순 로딩=Progress Indicator만 / 중요 작업=진행상태 텍스트+Progress Indicator, UI 결정 D 반영), **`AppEmptyState`(공통 컴포넌트, 문구/아이콘/Action 주입형 — UI 결정 C 반영, 화면마다 개별 제작 금지)**.
4. **어르신용 UI — 홈(일반 모드)부터**.
5. **쉬운 모드 UI** — §2 설계 반영, 일반 모드 이후 구현.
6. **보호자용 UI** — Mock 데이터 프리뷰 화면은 구현하지 않는다(UI 결정 E 확정). 연결 전 상태는 `AppEmptyState`로 "아직 연결된 어르신이 없습니다 → 어르신 연결하기" CTA를 표시. **v3**: 고지서 통계 UI(구조화 데이터 기반 카드/그래프)도 이 단계에서 함께 설계.
7. **긴급 도움 / 설정 / 지원 화면**.
8. **(v3 신규) 답변 신뢰도 표시** — `analysis` 결과를 보여주는 모든 화면(문서 분석 결과, 문자 확인 결과)에 공통으로 붙는 표시 요소이므로, 개별 결과 화면 UI가 안정된 뒤(4단계 이후) 공통 컴포넌트로 추가.
9. **(v3 신규) 카메라 플래시 제어** — `document_scan` 촬영 화면 UI(4단계)에 포함해 함께 구현.
10. **(v3 신규) 음성 비서 UI(진입 버튼/입력·처리중·답변 상태)** — 쉬운 모드 Main(5단계) 설계가 끝난 뒤, 가장 마지막에 추가되는 진입점으로 설계(다른 모든 기능에 연결되어야 하므로 대상 기능 UI가 먼저 존재해야 함).

---

## 5. 개발 우선순위 (Phase) — 확정 반영

> Architecture 결정이 모두 확정되어, v1에서 "선행 조건: OO 결정 필요"로 막혀 있던 항목들이 대부분 해소되었다. 남은 선행 조건은 `technical-decisions.md` §5 OPEN QUESTIONS(세부 구현 방식)뿐이다.
>
> **경로 표기 안내(v4)**: 아래 Phase 설명에서 `lib/features/<x>/` 같은 경로는 실제로는 `apps/senior/lib/features/<x>/` 또는 `apps/guardian/lib/features/<x>/`(해당 Phase가 다루는 앱에 따라)를 뜻한다. Phase 1은 두 앱과 6개 공용 패키지의 기반을 모두 만들었으므로, Phase 2부터는 각 Phase가 "어느 앱" 작업인지 명시한다.

### Phase 1 — 프로젝트 기반

- **구현 기능**: Supabase 프로젝트 생성, `core/network`의 `DioClient` 연결, `core/storage`(Secure+Local 분리) 골격, `.env`/`.env.example` 정비.
- **선행 조건**: 없음(Backend/DB 결정 완료).
- **예상 영향 범위**: `lib/core/network/`, `lib/core/storage/`(신규), `.env*`.
- **테스트 항목**: 헬스체크 연결 테스트 1건, `core/storage`의 Secure/Local 각각 read/write 단위 테스트.
- **완료 조건**: `dart format .` / `flutter analyze` / `flutter test` 통과, Supabase 실연결 확인.

### Phase 2 — 인증(Auth) — Senior/Guardian 각자 구현 (v7: **구현 완료**)

> **v7 완료 보고**: 아래 계획대로 두 앱 각자 구현했다. 실제 파일 구조·DB migration·Edge Function 목록은 `technical-decisions.md` §1-3-A "Phase 2 구현 완료 요약" 참고. 요약: 가입/로그인/PIN 설정/PIN 재확인/PIN 분실/로그아웃/role 선택 전체 흐름을 코드로 구현했고, `dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug` 모두 통과(양쪽 앱). Supabase 프로젝트가 없는 로컬 개발 환경이라 **실제 서버 통신(OTP 발송, Edge Function 호출, RLS 적용)은 검증하지 못했다** — 이는 라이브 Supabase 프로젝트 연결 후 별도로 확인해야 한다. Guardian 생체인증(OPEN QUESTIONS 18)은 계획대로 이번 범위에서 제외했다.

- **구현 기능** (`technical-decisions.md` §1-3-A 설계 그대로 구현, 두 앱 각자):
  - 가입: 전화번호 입력 → Supabase Phone OTP 발송/검증 → PIN 설정(`set-pin` Edge Function 호출, 내부적으로 pgcrypto DB 함수로 bcrypt 해시) → 온보딩 계속. 이미 반대쪽 앱에 같은 번호로 가입되어 있으면 안내 문구 표시 후 계속 진행(`feature-spec.md` MODIFY-12).
  - 앱 재진입: 라우터 가드가 `hasValidSession`/`pinVerified`를 확인해 로그인/PIN/홈 중 적절한 화면으로 분기. PIN 입력 시 `verify-pin` Edge Function 호출, 성공하면 `pinVerifiedProvider`(인메모리, 비영속) true 세팅. **idle timeout: Senior 15분 / Guardian 5분(고정값)**.
  - 새 기기: 로컬 세션 없음 → OTP 재인증 → 기존 PIN 유지 또는 재설정 선택.
  - PIN 분실: "PIN을 잊으셨나요?" → OTP 재인증 → `reset-pin` Edge Function.
  - 로그아웃: `pinVerifiedProvider` 리셋 + `auth.signOut()`.
  - Guardian 생체인증(지문/FaceID)은 **이번 Phase 2 범위에 포함하지 않는다**(OPEN QUESTIONS 18).
  - (Backend 측, 이 저장소 범위 밖일 수 있음 — 별도 확인 필요) Edge Function 4종(`set-pin`/`verify-pin`/`reset-pin`/`delete-account`)은 PIN 해시 계산을 직접 하지 않고 **pgcrypto 기반 Postgres `SECURITY DEFINER` 함수**(`set_pin`/`verify_pin`)를 호출하는 얇은 계층으로 구현. `pin_credentials`/`user_roles` 테이블 + RLS(클라이언트 접근 전면 차단), `guardian_links`에 `elder_id != guardian_id` CHECK 제약 추가.
- **선행 조건**: Phase 1 완료. **Architecture 결정은 v6에서 전부 완료됨 — 이 Phase를 막는 미확정 사항이 없다.** (PIN 해시는 Argon2id가 아니라 bcrypt/pgcrypto로 확정 — 실제 Supabase Edge Function 2초 CPU 제한과 Deno Argon2 라이브러리 성숙도를 웹 조사로 검증한 결과.) Guardian 생체인증(18번)만 여전히 OPEN이나 Phase 2 범위 밖이라 착수를 막지 않는다.
- **예상 영향 범위**: `apps/<app>/lib/features/auth/`(OTP/PIN 화면, UseCase), `apps/<app>/lib/core/auth/pin_verified_provider.dart`(신규, idle timeout 타이머 포함), `apps/<app>/lib/app/router/`(redirect 가드 확장), `apps/<app>/lib/core/storage/`(Session은 Supabase SDK 위임 — PIN 관련 로컬 저장은 하지 않음).
- **테스트 항목**: OTP 검증 성공/실패, `verify-pin` 성공/실패/lockout 도달 UseCase 테스트, `pinVerifiedProvider`가 앱(위젯 트리) 재생성 시 항상 false로 시작하는지 Widget Test, idle timeout 경과 후 게이트가 다시 잠기는지 테스트(Senior 15분/Guardian 5분 각각), 라우터 가드 3분기(세션 없음/세션 있으나 PIN 미확인/PIN 확인됨) 각각의 리다이렉트 테스트, Repository Failure 변환 테스트.
- **완료 조건**: 가입(OTP+PIN)→앱 재시작→PIN 재확인→로그아웃 전체 흐름이 Supabase와 통신하며 동작. PIN이 클라이언트 어디에도(로컬 저장소 포함) 저장되지 않음을 코드 리뷰로 확인. `pin_credentials` 테이블에 클라이언트 role로 직접 접근 가능한 경로가 없음을 RLS 정책 리뷰로 확인. bcrypt 해시가 Edge Function이 아니라 DB 함수(pgcrypto)에서 계산됨을 코드 리뷰로 확인.

### Phase 3 — 어르신/보호자 UI 골격 + 쉬운 모드 Main + Design System 확장 (v8: **구현 완료, 범위 재조정**)

> **v8 완료 보고**: 실제 구현 범위는 사용자의 Phase 3 착수 지시(UI/UX 리서치 기반 재설계)에 따라 원래 계획에서 조정됐다 — Guardian UI 골격(1:N 어르신 선택 구조 포함)이 이 Phase로 앞당겨졌고, "보호자 등록 요청"은 `connection` feature 자체가 아직 없어 온보딩 안에서 UI만 존재(실제 `pending` row 생성 없음, 정직하게 "곧 제공 예정" 안내로 대체).

- **구현 완료**: 온보딩(접근성 설정은 `LocalStorageService`에 실제 저장, 내 정보/보호자 등록은 UI만 — 저장할 백엔드 없음), Senior 홈(정보/홈/기록/더보기 4탭, 쉬운 모드는 Main 진입 경험으로 구현), Guardian 홈(홈/알림/기록/통계/더보기 5탭, `AppElderSwitcher`+`selectedElderIdProvider`로 1:N 구조 선반영 — `connection` feature 부재로 항상 빈 리스트), `profile`/`settings` 기본형(둘 다 UI만 또는 로컬 저장, 로그아웃/회원탈퇴는 Phase 2 usecase 실연동), Design System 컴포넌트 13개 추가.
- **미구현(정직하게 Empty State)**: `welfare_center`/`info`/`analysis`/`schedule`/`notification`/`connection` — 도메인 계층 자체가 없어 관련 탭은 전부 `AppEmptyState`.
- **테스트**: Senior/Guardian 각 앱 기존 스위트 그대로 통과(45/43개, Phase 3는 신규 UI 골격에 별도 유닛 테스트를 추가하지 않음).
- **완료 조건 충족 여부**: 온보딩→홈 진입, 쉬운/일반 모드 전환은 충족. "보호자 등록 요청이 pending 상태로 생성됨"은 **미충족**(connection feature가 Phase 5이므로 구조적으로 불가능 — 임의로 앞당겨 구현하지 않음).

### Phase 4 — 어르신 문서 촬영(카메라+분석 요청 골격) (v8: **구현 완료, 범위 재조정**, v14: **AI 분석 백엔드 실제 연결 완료**)

> **v8 완료 보고**: 사용자의 Phase 4 착수 지시에 따라 범위가 "카메라+권한+플래시+촬영+분석 요청 골격"으로 좁혀졌다 — `welfare_center`/`info`/`analysis`(기록 목록)/`schedule`은 이번에 포함하지 않았다(도메인 자체가 아직 없음). "원본 즉시 삭제"/실제 업로드는 **분석 백엔드가 없어 검증할 대상 자체가 없음**(NOT AVAILABLE, 아래 참고).
>
> **v14 추가 구현**: v8에서 미뤘던 "실제 이미지 업로드/AI 분석/원본 삭제"를 연결했다. `analyze-document` Edge Function(Anthropic Claude, `ANTHROPIC_API_KEY` — v13의 `analyze-message`와 동일 시크릿 재사용)을 신규 작성해 `AnalysisRepositoryImpl`이 항상 `UnavailableFailure`이던 것을 실제 호출로 교체했고, `document-photos` Storage 버킷(migration `20260814000006`)을 신규 작성해 클라이언트가 본인 JWT로 사진을 업로드하도록 연결했다. Edge Function은 분석 성공/실패와 무관하게 원본을 즉시 삭제한다(§1-8). 이 환경에는 `ANTHROPIC_API_KEY`/실제 Supabase 프로젝트가 없어 실제 AI 호출/실제 업로드는 여전히 **NOT AVAILABLE** — 코드 경로와 정적 검토, Dart 단위테스트(mocktail)까지만 검증했다. 상세는 `technical-decisions.md` v14 항목.

- **구현 완료(v8)**: `document_scan`의 카메라 권한(허용/거부/영구거부/제한 4상태) → 카메라 프리뷰(플래시 OFF/ON/자동 실제 전환) → 촬영 → 결과 확인(재촬영/분석하기) 전체 플로우. `AnalysisResult` 모델 재검토 완료(신규 필드 불필요, `technical-decisions.md` §6).
- **구현 완료(v14)**: 분석 요청이 실제 `analyze-document` Edge Function을 호출한다 — Storage 업로드(`document-photos` 버킷, 본인 폴더 한정 INSERT RLS) → Edge Function이 service role로 다운로드/분석 → `analysis_results` insert → 원본 즉시 삭제(`finally`, 성공/실패 무관) → reason-code 기반 `Failure` 매핑(`AuthFailure`/`ValidationFailure`/`UnavailableFailure`/`ServerFailure`/`UnknownFailure`). `UnavailableFailure`는 이제 "백엔드가 아예 없음"이 아니라 "AI provider 시크릿 미설정" 같은 정직한 런타임 조건에서만 나온다.
- **미구현**: `welfare_center`, `info`, `analysis`(기록 리스트 — Guardian 쪽은 Phase 6에서 구현됨, Senior 쪽 기록 열람은 여전히 없음), `schedule`, 고지서 구조화 필드의 실제 값 채우기 스키마 확정(여전히 OPEN QUESTIONS 12, `AnalysisResultView`는 스키마 무관 제네릭 렌더러로 계속 동작).
- **테스트**: v8 26개 + **v14 신규**(`analysis_repository_impl_test.dart` 8개 — 성공/서버측 `ok:false`/`FunctionException` reason별 매핑 5종/Storage 업로드 실패/미로그인/malformed 응답, 기존 위젯 테스트 2개는 `FakeAnalysisRepository` override로 조정) — `document_scan` 스위트 합계 27개, Senior 앱 전체 122개 `flutter test` 통과.
- **완료 조건 재정의(v8, 여전히 유효)**: 카메라/권한/플래시/네비게이션 전체 플로우가 코드 수준에서 검증됨(**Code-level validation PASS**). **Physical device validation NOT AVAILABLE** — 이 환경에 Android 실기기/에뮬레이터가 없어 실제 카메라 하드웨어 동작은 확인하지 못함(`flutter build apk --debug` 성공까지만 확인).
- **완료 조건 재정의(v14)**: (원래 조건인 "실제 사진 업로드→analysis_results 저장" 대신) 업로드/분석/삭제/DB insert에 이르는 전체 코드 경로가 실제로 연결됨(**Code-level validation PASS**). **Live backend validation NOT AVAILABLE** — `ANTHROPIC_API_KEY`/실제 Supabase 프로젝트가 없어 실제 AI 호출·실제 Storage 업로드·`analysis_results`에 실제 row가 쌓이는지는 확인하지 못했다.

### Phase 5 — 어르신↔보호자 연결(Connection) — QR 기반 (v9: **구현 완료**)

> **v9 완료 보고**: OPEN QUESTIONS 2번(전화번호 vs 연결 코드)을 **QR 코드 기반**으로 확정(`technical-decisions.md` §1-6)한 뒤, 계획대로 두 앱 각자 구현했다. Backend는 migration 3개(`connection_tokens` 테이블, `create_connection_token`/`redeem_connection_token` DB 함수, `guardian_links` insert/update 정책 — 전이 검증 트리거 포함) + Edge Function 2개(`create-connection-token`/`redeem-connection-token`)로 구성했다. `dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug` 전부 통과(양쪽 앱). Supabase 프로젝트가 없어 **실제 서버 통신(토큰 발급/QR 스캔/RLS 적용)은 검증하지 못했다** — 라이브 Supabase 연결 후 별도 확인 필요.

- **구현 완료**: `connection` feature(양 앱 domain/data/presentation). Senior 쪽 "보호자 연결" 화면(서버 발급 5분 유효 토큰을 `qr_flutter`로 QR 렌더링, 만료 시 재발급) + "연결된 보호자 목록" 화면(pending 수락/거절, accepted 연결 해제, 더보기 탭에 연결). Guardian 쪽 "어르신 연결하기" → QR 스캔 화면(`mobile_scanner`, 카메라 권한 거부 시 설정 이동 안내) → 연결 요청 생성 → "어르신 연결 관리" 화면(연결 해제, 더보기 탭에 연결).
- **Backend 설계 결정(구현 시 확정)**: `connection_tokens`는 `token`(PK, pgcrypto 랜덤 hex)/`elder_id`/`expires_at`/`used_at` — `pin_credentials`와 동일하게 클라이언트 직접 접근 전면 차단, `service_role`만 두 DB 함수를 통해 접근. `guardian_links` UPDATE는 양측 모두 RLS로 행에 접근 가능하되(`elder_id = auth.uid() or guardian_id = auth.uid()`), **어떤 상태 전이를 누가 할 수 있는지는 트리거가 검증**한다 — `pending→accepted/rejected`는 어르신만, `accepted→revoked`는 양측 모두(기존 온담앱이 보호자 측 연결 해제만 제공했던 것을 유지하는 차원). INSERT는 클라이언트 정책 자체가 없다 — pending row 생성은 오직 `redeem_connection_token` RPC(service_role)를 통해서만 가능.
- **예상 영향 범위(실제)**: `apps/senior/lib/features/connection/`, `apps/guardian/lib/features/connection/`(신규). Guardian 앱에 카메라 관련 패키지(`mobile_scanner`, `permission_handler`)가 처음 추가됨(`architecture.md` "어르신↔보호자 연결(QR)" 참고) — AndroidManifest/Info.plist 카메라 권한 항목도 함께 추가. Senior 앱에 `qr_flutter` 추가. `packages/models`의 `GuardianLinkStatus`에 `toDbValue()`/`fromDbValue()` 추가(기존 `UserRole` 패턴과 통일).
- **테스트**: 양 앱 각 4개 usecase 테스트(총 8개, Repository는 fake로 대체 — testing.md) — 위 "완료 조건 재정의"의 domain 분기(토큰 발급/목록 조회/수락·거절/해제, 빈 토큰 검증)를 커버. Widget/Integration 테스트는 실제 Supabase 없이는 의미 있는 흐름 검증이 어려워 이번 범위에 포함하지 않았다(NOT AVAILABLE 사유는 Phase 2와 동일).
- **완료 조건 재정의**: (원래 조건인 "실제 두 계정 간 연결이 QR 스캔+어르신 수락을 거쳐 성립" 대신) **Code-level validation PASS** — QR 발급/스캔/요청생성/수락·거절/해제 전체 플로우와 RLS/트리거 권한 검증이 코드·migration 수준에서 구현·검증됨. **Live backend validation NOT AVAILABLE** — Supabase 프로젝트가 없어 실제 토큰 발급·RLS 적용은 확인하지 못함(`flutter build apk --debug` 성공까지만 확인).

### Phase 6 — 보호자 핵심 기능(Guardian) + 고지서 통계 동기화 (v10: **구현 완료**)

> **v10 완료 보고**: OPEN QUESTIONS #12(고지서 통계 최종 데이터 항목)가 여전히 미결정이라, 계획했던 "고지서 통계 집계(월별/변화율 등)"는 이번에 구현하지 않았다 — 대신 스키마와 무관하게 항상 well-defined한 집계(분석 건수/위험 문자 건수)만 구현하고, 고지서 구조화 필드는 제네릭하게 나열만 한다. `lib/features/guardian/`이 아니라 `lib/features/analysis/`로 구현했다(receiving/기록/통계 3개 탭이 전부 같은 `analysis_results` 소스를 공유해 하나의 feature로 묶는 것이 architecture.md의 feature 결합 최소화 원칙에 더 부합 — "guardian" feature는 별도로 만들지 않았다). 아래 항목을 실제 구현 기준으로 갱신했다.

- **구현 완료**: 보호자 홈(안심 상태 — `RiskSummary.worst()`로 계산, 최근 활동 최대 3건), 알림 탭("받은 연락" — caution/dangerous만 필터링), 기록 탭(전체 `analysis_results` 리스트 + 상세), 통계 탭(이번 달 분석 건수/위험 문자 건수 `AppStatCard` + 추세 문장, 고지서는 기록별 구조화 필드 원본 나열 + "아직 결정되지 않았어요" 안내). `connectedEldersProvider`가 Phase 5의 실제 `guardian_links`(accepted만, pending/rejected/revoked 제외)를 소스로 사용하도록 교체됨. 어르신 표시 이름은 `users`/`profile` 테이블이 여전히 없어 임의 문자열 대신 `elder_id` 앞 8자리로 대체("어르신 (12345678)" — Phase 5 `ConnectionListPage`와 동일한 표현, 새로 지어내지 않음).
- **Backend**: `analysis_results` 테이블(`supabase/migrations/20260814000001_create_analysis_results.sql`) 신규 — select RLS 2개(본인 elder, `accepted` guardian_link 보유 guardian), insert/update/delete 정책은 어떤 client role에도 없음(§1-7 원칙대로 서버 AI 파이프라인만 작성 가능). `packages/models`의 `AnalysisType`/`ReliabilityLevel`/`RiskLevel`에 `UserRole`/`GuardianLinkStatus`와 동일한 `toDbValue()`/`fromDbValue()` 추가.
- **선행 조건**: Phase 4, 5 완료 — 충족.
- **실제 영향 범위**: `apps/guardian/lib/features/analysis/`(신규, domain/data/presentation), `apps/guardian/lib/features/home/presentation/pages/{home_tab_page,notification_tab_page,records_tab_page,statistics_tab_page}.dart`(실데이터 연결로 교체), `apps/guardian/lib/features/connection/presentation/providers/connected_elders_provider.dart`(실데이터 연결), `packages/models/lib/src/{analysis_type,reliability_level,risk_level}.dart`(db-value 헬퍼 추가), `supabase/migrations/`(신규 1개).
- **테스트**: Guardian 신규 19개 — `connectedEldersProvider`(0/1/2명, pending·rejected·revoked 제외, 이름이 실제 elderId 기반인지) 7개, `analysis` domain(usecase 4개, `RiskSummary` 4개, `AnalysisStats` 5개) 13개, `AnalysisRecordsNotifier`(선택된 어르신 없음/선택/전환 시 재조회) 3개. Widget 6개(`AnalysisRecordDetailPage` — 신뢰도 문장/위험 배지 유무/원문 유무/구조화 필드 렌더링). RLS 보안 테스트("연결 안 된 elder 접근 차단", "revoked 연결 접근 차단")는 실제 Supabase 프로젝트가 없어 실행 불가 — 대신 migration의 정책 정의 자체가 정적 리뷰 대상이다(§4, §15 참고. **NOT AVAILABLE**로 명시).
- **완료 조건 재정의**: (원래 조건 그대로 충족) 연결된 어르신의 실제 데이터만 보호자 앱에 반영되고(RLS로 강제, 앱 레이어에서 추가로 걸러내지 않음), 비연결 상태에서는 명확한 Empty State가 표시됨. 고지서 통계는 "구조화 데이터만으로 표시"까지는 충족하되, 통계 항목 자체(OPEN QUESTIONS #12)가 미확정이라 집계·차트는 보류 — 원본 구조화 필드 나열까지만 구현.

### Phase 7 — 문자/위험 기능 (v11: **구현 완료, 범위 재조정**, v13: **위험분석 백엔드 실제 연결 완료**)

> **v11 완료 보고**: 원래 계획은 "Android 전용"이었으나, 사용자 결정에 따라 **iOS도 붙여넣기/직접 입력 기반으로 함께 구현**했다(자동 SMS 접근은 여전히 Android 전용). "서버 Risk Detection 호출"과 "보호자에게 알리기 → `notification` 이벤트 생성"은 실제 분석 백엔드(Edge Function)가 아직 없어 이번 범위에 포함하지 않았다 — `document_scan`과 동일하게 분석 요청은 항상 `UnavailableFailure`로 귀결된다(가짜 위험 판정 없음). `notification` feature 자체가 아직 없으므로(Phase 8) "보호자에게 알리기"는 구조적으로 불가능해 임의로 앞당기지 않았다.
>
> **v13 추가 구현**: v11에서 미뤘던 두 가지를 모두 연결했다. `analyze-message` Edge Function(Anthropic Claude, §1-7)을 신규 작성해 `MessageRiskRepositoryImpl`이 실제로 호출하도록 교체했고(`document_scan`은 이번 범위 밖 — 여전히 `UnavailableFailure`), 위험 판정(`caution`/`dangerous`) 시 서버가 `guardian_links`(accepted)를 직접 조회해 대상 보호자를 정하고 `send-notification`(Phase 8)을 호출하도록 연결했다. 이 환경에는 `ANTHROPIC_API_KEY`/실제 Supabase 프로젝트가 없어 실제 AI 호출/실제 DB 반영은 **NOT AVAILABLE** — 코드 경로와 정적 검토, Dart 단위테스트(mocktail)까지만 검증했다. 상세는 `technical-decisions.md` v13.

- **구현 완료**: `apps/senior/lib/features/message_check/`(domain/data/presentation). **Android**: `flutter_sms_inbox` 기반 최근 SMS inbox 조회, `permission_handler`의 `Permission.sms`로 권한 상태(granted/denied/permanentlyDenied) 처리, 문자 목록 → 문자 확인(상세) → 분석하기 흐름. **iOS(및 자동 조회 미지원 플랫폼)**: `SmsPermissionStatus.unsupported`로 자동 판별되어 클립보드 붙여넣기(비어 있어도 오류 아님) + 직접 입력 화면으로 바로 연결. 두 플랫폼 모두 마지막에 기존 `AnalysisResultView`(이번에 `document_scan`에서 `apps/senior/lib/core/widgets/`로 승격)를 그대로 재사용해 결과를 표시한다. Home 탭의 "문자 확인" 카드를 실제 진입점으로 연결(기존 `ComingSoonPage` placeholder 제거).
- **Architecture**: `SmsInboxRepository`(Android 자동 조회) / `MessageRiskRepository`(분석 요청, `document_scan`의 `AnalysisRepository`와 동일한 `UnavailableFailure` 패턴 — 입력 타입이 달라 인터페이스만 분리) 두 축으로 domain을 구성했다. Platform 분기는 `data/repositories/sms_inbox_repository_factory.dart` 한 곳(`Platform.isAndroid`)에서만 일어나고, presentation/domain은 플랫폼을 모른다. `SmsMessage`(domain entity)는 Android inbox 조회 결과와 iOS 수동 입력을 동일하게 표현한다(`sender`가 null이면 수동 입력).
- **미구현(정직하게 Unavailable/구조 부재)**: ~~실제 위험도 분석 AI/Edge Function~~ → **v13에서 구현**(`analyze-message`, 아래 참고) — 단 이 환경에 AI provider 키가 없어 실제 호출은 NOT AVAILABLE. ~~"보호자에게 알리기"~~ → **v13에서 구현**(위험 판정 시 서버가 `send-notification` 호출) — 단 실제 FCM 발송은 여전히 NOT AVAILABLE. 새 문자 자동 감지(백그라운드 리스너)는 이번에도 의도적으로 제외(인터페이스는 확장 가능하게 남김).
- **Guardian**: 신규 feature 없음 — Phase 6에서 이미 `AnalysisType.message`를 "문자 확인" 라벨/아이콘으로 분기 처리하고 있음을 코드로 확인(`analysis_record_card.dart`/`analysis_record_detail_page.dart`). `analysis_results` RLS도 `type` 컬럼과 무관하게 이미 커버하므로 Backend 변경 없음.
- **선행 조건**: Phase 4, 6 완료 — 충족. SMS 패키지 선정(`technical-decisions.md` OPEN QUESTIONS 4번)을 이번에 `flutter_sms_inbox`로 확정(DECIDED).
- **실제 영향 범위**: `apps/senior/lib/features/message_check/`(신규), `apps/senior/lib/core/widgets/analysis_result_view.dart`(신규, `document_scan`에서 승격), `apps/senior/lib/features/document_scan/presentation/pages/document_scan_result_page.dart`(import만 변경, 로직 변경 없음), `apps/senior/lib/features/home/presentation/pages/home_tab_page.dart`(진입점 연결), `apps/senior/pubspec.yaml`(`flutter_sms_inbox` 추가), `apps/senior/android/app/src/main/AndroidManifest.xml`(`READ_SMS` 권한 추가). Guardian/Supabase 변경 없음.
- **테스트**: Senior 신규 37개(v11) — domain usecase 10개(권한 3상태+unsupported, 최근 조회, 위험 분석), data 5개(Unsupported repository, factory가 비Android 호스트에서 안전하게 fallback하는지, MessageRiskRepositoryImpl), presentation 22개(권한별 진입 분기 4, 목록/타일/붙여넣기 위젯, 결과 화면 Unavailable 상태, Home 연결). 기존 `document_scan`의 `AnalysisResultView` 테스트는 `core/widgets/`로 이동(내용 동일, import만 변경 — 커버리지 손실 없음). **v13 추가**: `message_risk_repository_impl_test.dart` 신규 6개(성공/`ok:false`/`FunctionException` reason별 매핑/malformed 응답 안전 처리 — mocktail로 datasource mock). 기존 위젯 테스트 2개(`message_risk_result_page_test.dart`, `message_check_navigation_test.dart`)는 repository가 실제 Supabase 의존을 갖게 되어 `messageRiskRepositoryProvider`를 `FakeMessageRiskRepository`로 override하도록 조정했다 — assertion(Unavailable 문구)은 그대로 유지, 삭제/약화 아님. `dart format`/`flutter analyze`/`flutter test` 양쪽 앱 통과, Phase 1~7 regression 전부 PASS 확인.
- **완료 조건 재정의**: (원래 조건인 "Android 실기기에서 문자 분석→보호자에게 알리기까지 동작" 대신) **Code-level validation PASS** — 권한 분기/목록/붙여넣기/분석 요청 전체 플로우가 코드 수준에서 검증됨. **Physical device validation NOT AVAILABLE** — 이 환경에 Android 실기기/에뮬레이터가 없어 실제 SMS 하드웨어 읽기 동작은 확인하지 못했다. **v13**: 위험분석 백엔드 코드는 실제로 연결됐으나 AI provider 키/Supabase 프로젝트가 없어 실제 분석 호출은 여전히 **NOT AVAILABLE**.

### Phase 8 — 알림(Notification)

- **구현 기능**: `features/notification`(FCM 토큰 등록/수신/로컬 표시/딥링크), 서버 측 알림 발송 트리거(`notifications` 테이블 insert → Edge Function → FCM).
- **선행 조건**: Phase 7 완료.
- **예상 영향 범위**: `lib/features/notification/`(신규), 서버 측 Edge Function(이 저장소 범위 밖일 수 있음 — 별도 확인 필요).
- **테스트 항목**: 권한 요청 흐름 Widget Test, 알림 수신 시 올바른 화면 딥링크 통합 테스트, FCM 토큰 갱신/무효화 테스트(§2-5).
- **완료 조건**: 위험 문자 발생 시 보호자 기기에 실제 Push 도달, 알림 탭 시 해당 "받은 연락" 상세로 이동.
- **진행 상황(v12, Backend만 구현)**: 서버 측 절반만 실제로 구현했다 — `lib/features/notification/`(Flutter 클라이언트, FCM 토큰 등록/수신/로컬 표시/딥링크)은 **아직 없음**. `notifications`/`fcm_tokens` migration 2개(`technical-decisions.md` §4 v12)와 `send-notification` Edge Function(호출자-대상 간 `accepted` guardian_links 확인 → `notifications` row 생성 → `fcm_tokens` 조회 → FCM legacy HTTP API 발송 시도)을 작성했다. 이 환경에 실제 Firebase 프로젝트/`FCM_SERVER_KEY`가 없어 실제 Push 발송 자체는 **NOT AVAILABLE**(구조만 완성, `pushSent: false` 경로로 정직하게 응답). Supabase CLI를 새로 설치할 수 없는 환경 제약으로 migration/Edge Function 모두 **정적 검토만** 했고 실제 `supabase db push`/`functions serve` 실행 검증은 하지 않았다. "위험 문자 발생 시 보호자 기기에 실제 Push 도달" 완료 조건은 **미충족** — 이번 작업은 Phase 8 완료가 아니라 그 전제 인프라만 마련한 것이다. 상세는 `technical-decisions.md` v12 항목.
- **진행 상황(v13, Guardian 클라이언트 완료 + 결함 2건 수정 + Phase 7 연결)**: `apps/guardian/lib/features/notification/`(domain/data/presentation 3계층 — FCM 토큰 등록/무효화, foreground/background 수신, `NotificationTabPage` 실시간 알림 목록, `AnalysisRecordDetailPage` 딥링크)을 실제로 구현했다. 통합 검증 중 발견한 두 silent failure(읽음 처리·로그아웃 토큰 삭제가 RLS에 막혀 조용히 0건 처리)를 `20260814000004` migration(RPC + delete 정책)으로 수정하고 Guardian 코드도 그에 맞춰 교체했다. Phase 7이 이번에 `send-notification`을 실제로 호출하도록 연결되면서 `send-notification` 자체의 버그(FCM `data`에 `elder_id`/`analysis_result_id` 누락 — 푸시 탭 딥링크가 항상 실패)도 발견해 수정했다. Guardian `flutter test` 100/100(RLS 수정 커버 6개 포함), `dart format`/`flutter analyze`/`flutter build apk --debug` 통과. **여전히 NOT AVAILABLE**: 실제 Supabase 연결(CLI/Docker/credentials 없음), 실제 FCM 발송/실기기 수신, 실제 AI 분석 호출(`ANTHROPIC_API_KEY` 없음) — 따라서 "위험 문자 발생 시 보호자 기기에 실제 Push 도달" 완료 조건은 **여전히 미충족**. 코드/구조는 전부 실동작 가능한 형태로 연결됐지만 이 환경 밖(실제 Supabase 프로젝트 + Firebase 프로젝트 + AI 키)에서만 최종 검증 가능하다. 상세는 `technical-decisions.md` v13 항목.

### Phase 9 — UI 개선(쉬운 모드 완성 + 디자인 다듬기 + 답변 신뢰도) (v15: **구현 완료**)

- **구현 기능**: 쉬운 모드 Main 완성(하단 Navigation 포함, 핵심 기능 최소 동선 확정), 접근성 재검수, 긴급 도움/지원 화면 마감. **v3: 답변 신뢰도 UI**(`analysis` 결과가 표시되는 모든 화면에 "높음/보통/낮음"류 사용자 친화적 표현 추가 — 숫자·복잡한 그래프 배제, `ui-spec.md` 신뢰도 표현 규칙 참고).
- **선행 조건**: Phase 3~8이 일반 모드에서 안정적으로 동작. Phase 4에서 신뢰도 메타데이터가 이미 저장되고 있어야 함.
- **예상 영향 범위**: 전 feature `presentation/` 계층, 특히 `document_scan`/`message_check`/`analysis`/`guardian`의 결과 표시 화면.
- **테스트 항목**: 두 모드 동일 UseCase 호출 검증, 접근성 대비 점검, 재실행 후 쉬운 모드 유지 확인, 신뢰도 값→사용자 표현 매핑 단위 테스트(OPEN QUESTIONS 11의 기준 확정 후).
- **완료 조건**: 쉬운 모드 토글만으로 하단 Navigation까지 포함한 전체 앱이 일관 전환. 분석 결과 화면마다 신뢰도 안내가 일관되게 표시됨.

> **v15 완료 보고**: 착수 전 코드 확인에서 "답변 신뢰도 UI"는 이미 Phase 4/7에서 `AppConfidenceIndicator`(design_system)/`AnalysisResultView`(core/widgets, `document_scan`·`message_check` 공유)로 구현 완료돼 있어 재작업 없이 그대로 뒀다. 나머지 3개 항목만 이번에 구현했다.

- **긴급 도움 실제 전화 연결(구현 완료)**: `apps/senior/lib/features/emergency_help/domain/{repositories/dialer_repository.dart,usecases/call_phone_usecase.dart}` + `data/repositories/dialer_repository_impl.dart`(`url_launcher`) 신규. 119/112/118은 `tel:` URI로 실제 다이얼러를 연다. "보호자에게 전화"는 `guardian_links`가 `guardian_id`만 가지고 있어(전화번호를 노출하는 `users`/profile 테이블이 이 저장소에 없음) 실제 연결 대상이 없다 — 가짜 번호로 연결을 시도하는 대신 "보호자 전화번호를 아직 알 수 없어요" 안내로 정직하게 남겼다(가짜 연결 없음, §1-8/Phase 6와 동일한 원칙).
- **지원(고객 지원) 화면(신규 구현)**: `support` feature 디렉터리가 완전히 비어 있던 것을 확인하고 `SupportPage`/`PrivacyInfoPage`를 신규 작성했다(`presentation/`만 있는 정적 화면 — 저장할 데이터가 없어 domain/data 계층 불필요, architecture.md "작은 기능은 구조를 전부 강제하지 않는다"). 실제 고객센터 연락처(전화/이메일)는 이 저장소에 사업 정보가 없어 사용자 결정에 따라 정직한 준비중 안내로 남겼다. 개인정보 보관 안내는 이 저장소에서 실제로 확정·구현된 정책(PIN 미저장/사진 원본 즉시삭제/accepted guardian만 결과 조회/회원탈퇴 즉시삭제)만 서술하고, 분석 결과 원문 보관 기간처럼 미확정인 항목(§5 OPEN QUESTIONS 5번)은 확정된 척하지 않고 "아직 정해지지 않았다"고 그대로 안내한다. `MoreTabPage`의 "고객 지원" 메뉴를 `ComingSoonPage`에서 `SupportPage`로 교체했다.
- **쉬운 모드 하단 Navigation(구현 완료, OPEN QUESTIONS 8 DECIDED)**: 탭 구성(정보/홈/기록/더보기 4개)은 그대로 두고 스타일(아이콘·라벨 크기)만 확대하는 방향으로 결정했다. `design_system`에 `AppEasyMode` 토큰(`navIconScale = 1.3`, `navBarHeight = 80`)을 추가하고 `AppBottomNavigation`에 `large` 파라미터를 더해 아이콘 크기/라벨 스타일/바 높이를 확대한다. `HomeShellPage`가 `easyModeProvider`를 watch해 `large: easyMode`로 전달 — 쉬운 모드 토글이 하단 Navigation까지 일관되게 적용된다(완료 조건 충족). Guardian 앱은 `large`를 전달하지 않아(기본값 `false`) 영향 없음.
- **접근성 재검수**: 기존 위젯(`AppIconButton`의 48×48 최소 터치영역+tooltip, `FlashToggleButton`/`HomeFeatureLargeButton`/`_ShutterButton`/`AppHeader`의 `_BackLink`)이 이미 `Semantics(button:true, label:...)`와 44px 이상 터치 영역을 준수하고 있음을 코드 리뷰로 확인했다(추가 수정 불필요). 누락을 하나 발견해 수정: 긴급 도움 `FloatingActionButton`에 `tooltip`이 없어 스크린 리더가 라벨 없이 읽던 것을 `tooltip: '긴급 도움'`으로 고쳤다.
- **테스트 중 발견한 실제 버그**: `EmergencyHelpSheet`에 처음 작성한 widget test가 `RenderFlex overflowed`로 실패해, 지금까지 이 화면에 테스트가 없어 발견되지 못한 실제 레이아웃 오버플로(모달 시트 높이가 작을 때 4개 연락처 행 + 헤더가 넘침)를 확인했다 — `SingleChildScrollView`로 감싸 수정했다.
- **실제 영향 범위**: `apps/senior/lib/features/emergency_help/`(domain/data/presentation 신규 추가), `apps/senior/lib/features/support/`(신규), `apps/senior/lib/features/home/presentation/pages/{more_tab_page,home_tab_page,home_shell_page}.dart`, `packages/design_system/lib/src/{tokens/app_easy_mode.dart(신규),widgets/app_bottom_navigation.dart}`, `apps/senior/pubspec.yaml`(`url_launcher` 추가).
- **테스트**: Senior 신규 8개(`CallPhoneUseCase` 3, `EmergencyHelpSheet` 3, `SupportPage` 2) — Senior `flutter test` 122→130개 전부 통과. `design_system` 신규 2개(`AppBottomNavigation` large 모드) — 이 패키지의 첫 테스트. `dart format`/`flutter analyze`(Senior/`design_system` 모두 0 issue, Senior 기존 info 2건은 이번 변경과 무관한 `auth` feature) 통과, `flutter build apk --debug` 통과.
- **완료 조건 충족 여부**: "쉬운 모드 토글만으로 하단 Navigation까지 포함한 전체 앱이 일관 전환" — **충족**(스타일 확대로 구현, 탭 구성 변경은 범위에서 제외하기로 결정). "분석 결과 화면마다 신뢰도 안내가 일관되게 표시됨" — **이미 충족**(Phase 4/7에서 공유 위젯으로 완료). 실기기 접근성 검증(TalkBack/VoiceOver 실사용)은 이 환경에 Android/iOS 실기기가 없어 **NOT AVAILABLE** — 코드 수준(Semantics/터치 영역) 검증까지만 확인했다.

### Phase 10 — 음성 비서(Voice Assistant) (v16: **구현 완료**)

- **구현 기능**: 음성 입력(STT) → 의도 분석 → 온담 기능 UseCase 호출 또는 서버 AI 처리 → 답변 → 음성 출력(TTS)의 기본 파이프라인. 최초 구현은 소수의 핵심 명령(예: "문서 찍어줘", "경로당 찾아줘")만 지원하는 것으로 범위를 좁히는 것을 권장.
- **선행 조건**: Phase 3~9 완료(연결할 대상 기능들이 이미 존재해야 함). **OPEN QUESTIONS 9~10(STT/TTS 서비스, AI 처리 방식) 결정 필수** — 이 Phase는 다른 어떤 Phase보다 선행 결정 의존도가 높다.
- **예상 영향 범위**: `lib/features/voice_assistant/`(신규), `home`(음성 비서 진입 버튼 추가).
- **테스트 항목**: STT 인식 실패/무음 시 폴백 UX 테스트, 의도 분류 정확도에 대한 수동 QA(자동화 단위 테스트로는 한계), 다른 feature UseCase 호출 시 Failure 전파 테스트, TTS 재생 실패 시 텍스트 표시 폴백 테스트.
- **완료 조건**: 지원 범위로 명시한 핵심 명령 2~3개가 음성 입력→기능 실행→음성 답변까지 실제로 동작.

> **v16 완료 보고**: 착수 전 OPEN QUESTIONS 9~10을 사용자 확인 후 DECIDED 처리했다(§5) — (9) 온디바이스 `speech_to_text`/`flutter_tts`, (10) 클라이언트 키워드 매칭(서버 AI 없음). "경로당 찾아줘" 예시는 `welfare_center` feature가 완전히 비어 있어(`.gitkeep`만 존재) 이번 범위에서 제외했다 — 지원 명령을 실제로 존재하는 기능 3개(문서 촬영/문자 확인/긴급 도움)로 좁히는 것도 함께 확인받았다.

- **구현 완료**: `voice_assistant` feature 전체(domain/data/presentation). `ClassifyVoiceIntentUseCase`가 순수 키워드 매칭(문서/서류/촬영/찍어 → `documentScan`, 문자/메시지/메세지 → `messageCheck`, 긴급/도와줘/도움/살려 → `emergencyHelp`, 그 외/빈 문자열 → `unrecognized`)으로 인식 텍스트를 분류한다. 마이크 권한은 `document_scan`의 `CameraPermissionStatus`/`CameraRepository`/`CameraPermissionDataSource`/`CameraPermissionNotifier` 구조를 그대로 미러링해 `MicPermissionStatus`/`MicRepository`/`MicPermissionDataSource`/`MicPermissionNotifier`로 구현했다(허용/거부/영구거부/제한 4상태, `VoiceAssistantPage`가 `document_scan_camera_page.dart`와 동일한 분기 구조로 처리). 실제 STT/TTS 엔진(`SpeechToText`/`FlutterTts`)은 `VoiceInteractionView`(`ConsumerStatefulWidget`)가 직접 소유한다 — `document_scan`의 `CameraPreviewView`가 `CameraController`를 직접 소유하는 것과 동일한 이유(하드웨어/UI-bound, disposable 컨트롤러는 Repository가 아니라 로컬 StatefulWidget 상태, flutter.md). ui-spec.md의 "음성 비서 상태" 표를 그대로 구현: 진입(마이크 버튼, "말씀해주세요") → 듣는 중(마이크 강조 애니메이션 — `AnimationController` 기반 pulse, "듣고 있어요" 텍스트 병행) → 처리 중(`AppLoading`의 "중요 작업" variant, "요청하신 내용을 확인하고 있어요") → 답변(화면에 답변 텍스트 표시 + "이동하기"/"다시 듣기" 버튼, 인식된 명령은 확인 후 이동 — 자동 네비게이션 없음, 사용자가 직접 "이동하기"를 눌러야 실제 화면 전환). 인식 실패/무음(STT `onError`/`onStatus('done')`이 최종 결과 없이 종료)은 하드 에러로 취급하지 않고 `unrecognized` 답변과 동일하게 "무슨 말씀인지 잘 이해하지 못했어요... '다시 말씀해주세요'"로 부드럽게 재시도를 유도한다(ui-spec.md "인식 실패/무음" 원칙 그대로). TTS 재생 실패는 조용히 무시한다 — 답변은 이미 화면에 텍스트로 표시되어 있어 음성 없이도 내용은 전달된다.
- **Home 진입점**: `home_tab_page.dart`의 "음성 비서" 카드를 `ComingSoonPage`에서 `VoiceAssistantPage`로 교체했다. 일반/쉬운 모드 모두 동일한 `HomeFeatureItem` 목록을 통해 진입하므로 Phase 9에서 구현한 쉬운 모드 확대 스타일이 자동으로 적용된다(별도 코드 불필요).
- **패키지/권한**: `speech_to_text ^7.4.0`, `flutter_tts ^4.2.5` 신규 추가(둘 다 pub.dev 최신 안정 버전 확인 후 채택). Android `RECORD_AUDIO` 권한, iOS `NSMicrophoneUsageDescription`/`NSSpeechRecognitionUsageDescription`을 추가했다(`speech_to_text`가 iOS에서 요구하는 두 키 모두 필요).
- **미구현/제외**: "경로당 찾아줘" 같은 `welfare_center` 연동 명령(feature 자체가 없음), 자유 발화 질의응답·서버 AI 의도분류(신규 OPEN QUESTIONS 23으로 남김), 새 문자 자동 감지 연동(음성 비서에서 message_check를 열어주기만 함, `message_check` 자체의 백그라운드 감지는 Phase 7에서도 의도적으로 제외됨).
- **실제 영향 범위**: `apps/senior/lib/features/voice_assistant/`(신규, domain/data/presentation), `apps/senior/lib/features/home/presentation/pages/home_tab_page.dart`(진입점 교체), `apps/senior/pubspec.yaml`(2개 패키지 추가), `apps/senior/android/app/src/main/AndroidManifest.xml`, `apps/senior/ios/Runner/Info.plist`. Guardian/Supabase 변경 없음.
- **테스트**: Senior 신규 9개 — `ClassifyVoiceIntentUseCase` 5개(문서/문자/긴급/빈 문자열/무관한 발화), mic permission usecase 4개(`CheckMicPermissionUseCase`/`RequestMicPermissionUseCase`, `document_scan`의 camera permission usecase 테스트와 동일 패턴, fake repository 사용). `flutter test` 130→139개 전부 통과. `VoiceAssistantPage`/`VoiceInteractionView`는 `speech_to_text`/`flutter_tts`의 플랫폼 채널에 의존해 이 저장소의 `document_scan_camera_page`/`CameraPreviewView`와 동일한 이유로 위젯 테스트를 작성하지 않았다(선례와 일관 — 플랫폼 채널 mock 없이는 의미 있는 검증이 어려움).
- **완료 조건 재정의**: (원래 조건인 "핵심 명령 2~3개가 음성 입력→기능 실행→음성 답변까지 실제로 동작" 대신) **Code-level validation PASS** — 권한 분기/STT 초기화/의도 분류/답변 표시/TTS 호출/화면 전환 전체 플로우가 코드 수준에서 검증됨(`flutter build apk --debug` 성공까지 확인). **Physical device validation NOT AVAILABLE** — 이 환경에 Android/iOS 실기기가 없어 실제 한국어 음성 인식 정확도, TTS 발화, 마이크 권한 프롬프트 동작은 확인하지 못했다. 빌드 로그에 `flutter_tts`/`speech_to_text`가 구버전 방식으로 Kotlin Gradle Plugin을 적용한다는 비차단 경고가 있음(빌드 자체는 성공) — 향후 Flutter SDK 업그레이드 시 재확인 필요.

### Phase 11 — 통합 테스트 및 안정화 (v17: **구현 완료**)

- **구현 기능**: 가입(OTP+PIN)→핵심기능→로그아웃, 보호자 연결요청→어르신수락→위험문자→Push알림, 음성 비서를 통한 핵심 기능 실행 등 주요 흐름 Integration Test.
- **선행 조건**: Phase 1~10 전체 완료.
- **예상 영향 범위**: `test/` 전반.
- **테스트 항목**: 핵심 흐름 2~3개 end-to-end 테스트, 계정 탈퇴 시 데이터/연결 삭제 정책(§2-10) 검증 테스트.
- **완료 조건**: `dart format .` / `flutter analyze` / `flutter test` 전체 통과, Android 빌드 검증(iOS는 `NOT AVAILABLE` 명시).

> **v17 완료 보고**: 착수 전 코드 탐색에서 `go_router`의 `hasSession` 게이트가 `Supabase.instance.client.auth.currentSession`을 직접 읽는 것을 확인했다(`app_router.dart`) — 세션 존재 여부를 fake로 override할 수 있는 provider가 아니라 Supabase SDK를 직접 호출하는 의도된 설계다(순수 클라이언트 상태 조작으로 인증 게이트를 우회할 수 없게 함). 이 환경에는 실제 Supabase 프로젝트가 없어 "가입(OTP+PIN)→핵심기능→로그아웃"을 라우터부터 관통하는 진짜 end-to-end 테스트는 구조적으로 **NOT AVAILABLE**다. 대신 이미 이 저장소에 확립된 관례(`message_check_navigation_test.dart` 등 — 인증을 통과한 상태를 가정하고 대상 화면을 직접 마운트, Fake Repository로 하위 계층을 대체)를 따라 실제로 커버되지 않았던 두 흐름을 통합 테스트로 채웠다.

- **버그 수정(안정화)**: Senior/Guardian 양쪽 `features/auth/presentation/providers/pin_notifier.dart`의 `deleteAccount()`가 성공 후 `pinVerifiedProvider`만 리셋하고 `signOutUseCase`를 호출하지 않고 있었다. `delete-account` Edge Function은 서버에서 `auth.admin.deleteUser`로 계정을 즉시 삭제하지만, 클라이언트의 로컬 Supabase 세션(JWT)은 자동으로 무효화되지 않는다 — 그 상태에서 라우터의 `hasSession` 게이트는 여전히 참이 되어 `pinEntry`(PIN 입력) 화면으로 리다이렉트할 수 있었다(삭제된 계정의 PIN을 입력하라는 화면이 뜨는 상황). 두 앱 모두 `deleteAccount()` 성공 시 `signOutUseCase`를 함께 호출하도록 수정했다.
- **코드 정합화**: `TextStyle(color: AppColors.error)` 하드코딩 4건을 발견해 `AppTextStyles.bodyLarge/bodyMedium.copyWith(color: AppColors.error)`로 교체했다(ui-design.md "TextStyle을 직접 만들지 않는다" 규칙 위반이던 기존 코드) — Senior/Guardian `settings_page.dart`의 "회원 탈퇴", Senior `guardian_list_page.dart`/Guardian `connection_list_page.dart`의 "연결 해제". `design_system`의 `AppConfirmDialog`에도 구조적으로 유사한 패턴이 하나 더 있으나, 이건 여러 feature가 공유하는 컴포넌트고 `null` 분기(테마 기본 스타일 유지)가 의도적으로 의미를 가지고 있어 페이지 레벨 4건과 성격이 다르다고 판단해 이번에는 그대로 두고 기록만 남긴다.
- **§2 item 10(계정 탈퇴 시 연결/데이터 삭제) 정적 검증**: `supabase/migrations/*.sql`을 전수 확인해 사용자 소유 테이블(`user_roles`/`pin_credentials`/`guardian_links`/`connection_tokens`/`analysis_results`/`notifications`/`fcm_tokens`) 전부가 `auth.users(id)`에 `on delete cascade`로 걸려 있음을 확인 — "본인 데이터 즉시 삭제"는 실제로 보장된다. 다만 원래 요구사항의 "어르신 탈퇴 시 보호자 쪽에 '연결이 종료되었습니다' 안내만 남기고"는 cascade가 `guardian_links` 행 자체를 완전히 지워버려 구현돼 있지 않다 — 안내를 보낼 대상 레코드가 존재하지 않는다. 이 간극을 이번에 임의로 설계·구현하지 않고 `technical-decisions.md` §5 신규 24번 OPEN QUESTIONS로 남겼다(tombstone 유지 여부, 어느 feature가 안내를 책임질지는 별도 제품 결정 필요).
- **통합 테스트 신규 작성**: `apps/senior/test/integration/`, `apps/guardian/test/integration/` 신규 디렉터리.
  - `delete_account_flow_test.dart`(양쪽 앱, 각 2개) — `SettingsPage`에서 "회원 탈퇴" 탭 → 확인 다이얼로그 → "탈퇴하기" 확정 시 `deleteAccount` 호출 + `signOut` 호출 + `pinVerifiedProvider`가 `false`로 리셋되는지 검증(방금 고친 버그의 회귀 테스트). 취소 시 아무 것도 호출되지 않는 것도 함께 검증.
  - `guardian_list_flow_test.dart`(Senior, 3개)/`connection_list_flow_test.dart`(Guardian, 3개) — 지금까지 `connection` feature는 domain usecase 단위 테스트만 있고 화면 단위(탭 → 실제로 목록이 바뀌는지) 테스트가 없던 gap을 메운다. Senior: pending 요청 수락 시 목록이 accepted로 갱신, 거절 시 목록에서 사라짐(rejected는 UI가 의도적으로 숨김), accepted 연결 해제는 확인 다이얼로그를 거쳐야 함. Guardian: pending 연결은 대기 문구만 보여주고 해제 버튼이 없음(수락/거절은 어르신 전용임을 화면 레벨에서 재확인), accepted 연결 해제 확인/취소 흐름.
- **실제 영향 범위**: `apps/senior/lib/features/auth/presentation/providers/pin_notifier.dart`, `apps/guardian/lib/features/auth/presentation/providers/pin_notifier.dart`(버그 수정), `apps/senior/lib/features/settings/presentation/pages/settings_page.dart`, `apps/guardian/lib/features/settings/presentation/pages/settings_page.dart`, `apps/senior/lib/features/connection/presentation/pages/guardian_list_page.dart`, `apps/guardian/lib/features/connection/presentation/pages/connection_list_page.dart`(TextStyle 정합화), `apps/senior/test/{features/auth/domain/fakes/fake_auth_repository.dart,integration/}`, `apps/guardian/test/{features/auth/domain/fakes/fake_auth_repository.dart,integration/}`(신규 테스트 + `signOutCalls`/`deleteAccountCalls` 카운터 추가). Backend/Supabase 변경 없음.
- **테스트**: Senior 신규 5개(`delete_account_flow_test.dart` 2, `guardian_list_flow_test.dart` 3) — `flutter test` 139→144개. Guardian 신규 5개(`delete_account_flow_test.dart` 2, `connection_list_flow_test.dart` 3) — `flutter test` 100→105개. 양쪽 모두 `dart format`/`flutter analyze`(0 issue, 기존 info 2건은 이번 변경과 무관한 `auth` feature)/`flutter build apk --debug` 통과.
- **완료 조건 재정의**: (원래 조건 중 "가입→핵심기능→로그아웃"/"보호자 연결요청→어르신수락→위험문자→Push알림"/"음성 비서 핵심 기능 실행"을 라우터·크로스앱·플랫폼 채널까지 관통하는 진짜 end-to-end로 실행하는 부분 대신) **Code-level integration validation PASS** — 인증 게이트 뒤의 화면들을 대상으로 한 다중 화면 흐름(계정 탈퇴, 보호자 연결 수락/거절/해제)이 실제로 상태 변화를 일으키는지 통합 테스트로 검증됨. `dart format`/`flutter analyze`/`flutter test` 전체 통과, Android 빌드 검증(양쪽 앱) 완료 — 명시된 완료 조건 문구를 그대로 충족한다. **NOT AVAILABLE**로 남는 것: (1) OTP+PIN 가입을 라우터부터 관통하는 실제 세션 기반 E2E(Supabase 세션은 fake로 대체할 수 없는 설계), (2) 보호자 연결요청→위험문자→Push알림의 실제 크로스앱 네트워크 E2E(실 Supabase/AI 키/FCM 프로젝트 없음, Phase 5~8부터 일관되게 NOT AVAILABLE), (3) 음성 비서의 실제 STT/TTS 플랫폼 채널 동작(Phase 10부터 일관됨), (4) iOS 빌드 검증(Windows 환경, 프로젝트 전반에 걸쳐 일관되게 NOT AVAILABLE).

> **관리자 시스템은 Phase 계획에 포함하지 않는다.** MVP 포함 여부 자체가 OPEN QUESTIONS 14로 미결정이라, 포함이 확정되면 별도 Phase(또는 별도 프로젝트)로 그때 계획한다.

---

## 6. 이번 단계에서 하지 않은 것

- 실제 Feature/API/Database/Provider/UI 구현
- Supabase 프로젝트 생성 / Database 생성
- `pubspec.yaml` package 추가
- 코드 작성 일체

`technical-decisions.md` §5 OPEN QUESTIONS 중 Phase 7(4번)/Phase 10(9~10번) 착수 전 필요한 항목이 정리되면(Phase 2는 v5, Phase 5는 v9에서 이미 해소됨), `feature-development` skill로 이어서 착수한다. Phase 6(보호자 핵심 기능)은 Phase 5가 방금 완료되어 착수 가능한 상태다.
