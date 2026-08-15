# Technical Decisions — Architecture 확정 및 보안 요구사항

> v1~v6은 `feature-development` 착수 **이전** 단계 산출물이었다. **v7부터는 Phase 2(Authentication)가 실제로 구현된 상태를 반영한다** — 아래 결정 사항 중 Phase 2 관련 항목은 더 이상 계획이 아니라 실제 코드/DB migration/Edge Function으로 존재한다(§1-3-A 하단 "Phase 2 구현 완료 요약" 참고).
>
> **개정 이력**
> - v1(초안): Backend/DB/인증/알림 등 11개 Architecture 결정 + 6개 UI 결정을 미확정 상태로 나열.
> - v2: 사용자가 Architecture 결정 11개 전체와 UI 결정 5개를 확정. 확정 내용을 반영하고, 남은 진짜 미확정 사항만 `OPEN QUESTIONS`로 분리했다.
> - v3: 신규 요구사항(음성 비서/쉬운 모드 Main 강화/카메라 플래시/답변 신뢰도/보호자 고지서 통계 동기화/관리자 시스템 PROPOSED)에 따른 미결정 사항 6개를 OPEN QUESTIONS에 추가하고, 전체 번호를 1~14로 재정리했다(§5).
> - v4: Phase 1(프로젝트 기반 구축)에서 "어르신 앱/보호자 앱을 하나의 앱으로 만들지, 별도 앱으로 만들지"가 **별도 2개 Flutter 앱 + Monorepo**로 확정되어 OPEN QUESTIONS 6번을 해소 처리했다. Monorepo 도구는 melos 대신 Dart/Flutter native pub workspace를 채택했다(근거는 `architecture.md` "저장소 구조" 참고).
> - v5: Phase 2 착수 전 OPEN QUESTIONS 1번(Supabase Auth OTP+PIN 결합 방식)을 설계·확정했다. **B안(PIN 검증은 Backend Edge Function이 전담, Session은 Supabase 표준 그대로 유지)**을 채택했다. 상세는 §1-3-A. 데이터 모델(§4)에 `pin_credentials`/`user_roles` 테이블을 추가하고 `users.pin_hash`/`users.role`을 제거했다. OPEN QUESTIONS를 15~18로 확장했다(§5).
> - v6: Phase 2 실구현 전, Authentication 관련 OPEN QUESTIONS 15~18 중 15·16·17을 실제 기술 조사(웹 검색)를 거쳐 확정했다. 가장 중요한 변경: **PIN 해시를 Argon2id에서 bcrypt(pgcrypto)로 변경**(Supabase Edge Function의 2초 CPU 제한과 Deno Argon2 라이브러리의 낮은 성숙도가 근거) — §1-3-A. Role 동시허용(B안)과 idle timeout(Senior 15분/Guardian 5분)도 확정. 18번(Guardian 생체인증)은 OPEN 유지, 19번(idle timeout 설정 가능 여부) 신규 추가.
> - v7: Phase 2(Authentication)를 실제로 구현했다. DB migration 4개(`user_roles`/`pin_credentials`/`pin_functions`+`has_pin`/`guardian_links`), Edge Function 5개(`set-pin`/`verify-pin`/`reset-pin`/`delete-account`/`has-pin` — 계획했던 최소 4개에 `has-pin`을 라우터 지원용으로 추가), Senior/Guardian 양쪽 앱의 Auth feature(domain/data/presentation) 전체, 라우터 3-state(+role) redirect, idle timeout(15분/5분)을 실제 코드로 구현했다. 상세는 §1-3-A 하단 "Phase 2 구현 완료 요약". Argon2id/bcrypt 등 이미 v6에서 확정된 결정 자체는 변경되지 않았다 — 실제 구현이 그 결정을 그대로 따랐음을 기록한다.
> - v8: Phase 3(Senior/Guardian UI 골격, Design System 컴포넌트 13개)에 이어 Phase 4(문서 촬영 카메라+분석 요청 골격)를 구현했다. `AnalysisResult` 도메인 모델을 재검토해 Phase 4 요구사항에 이미 충분함을 확인(신규 필드 추가 없음). `packages/core`의 `Failure` 계층에 `UnavailableFailure`를 신규 추가(백엔드 부재를 서버 오류와 구분). 상세는 §6 "Phase 4 구현 완료 요약".
> - v9: Phase 5(Connection) 착수 전 OPEN QUESTIONS 2번(보호자 연결 요청 입력 방식)을 **QR 코드 기반**으로 확정했다. 전화번호/연결 코드 직접 입력은 기본 방식으로 채택하지 않는다 — 어르신 앱이 서버 발급 단기 유효 토큰을 QR로 표시하고, 보호자 앱이 이를 스캔해 연결 요청(pending)을 생성하며, 어르신의 명시적 수락을 거쳐야 `accepted`가 된다. 상세는 §1-6. QR을 사용할 수 없는 상황의 fallback 방식은 이번에 함께 결정하지 않고 신규 OPEN QUESTIONS 20으로 남겼다(§5).
> - v10: Phase 6(Guardian 핵심 기능 + 고지서 통계)을 실제로 구현했다. `analysis_results` 테이블을 신규 migration으로 만들고, §2 item 6("위험 문자 원문/분석 결과는 (a) 본인, (b) accepted 보호자만 조회 가능")을 그대로 RLS 2개(select-only)로 구현했다 — client에는 어떤 insert/update/delete 정책도 주지 않는다. **OPEN QUESTIONS #12(고지서 통계 최종 데이터 항목)는 이번에도 확정하지 않았다** — Phase 6 완료 조건이 이 결정을 전제하지 않도록, 통계는 스키마 무관 집계(건수)만 구현하고 고지서 구조화 필드는 제네릭하게 나열만 한다. 차트 라이브러리(Decision 3, ui-component-spec.md)도 여전히 추가하지 않았다. 상세는 `implementation-plan.md` Phase 6 항목.
> - v11: Phase 7(위험 문자 확인, `message_check`)을 실제로 구현했다. OPEN QUESTIONS #4(Android SMS 패키지 선정)를 `flutter_sms_inbox` 기반 실제 SMS inbox 자동 조회로 DECIDED 처리했다 — Android는 실제 SMS 접근, iOS는 자동 접근 없이 복사/붙여넣기+직접 입력(Play Store 정책은 이번 구현 판단에서 고려하지 않음, 사용자 명시적 결정). `message_check`은 자체 분석 결과 모델을 만들지 않고 기존 `AnalysisResult`/`RiskLevel`/`document_scan`의 `UnavailableFailure` 패턴을 그대로 재사용했고, `AnalysisResultView`를 `document_scan`에서 `apps/senior/lib/core/widgets/`로 승격해 두 feature가 공유하도록 리팩터링했다. Guardian 앱은 Phase 6에서 이미 `AnalysisType.message`를 "문자 확인"으로 분기 처리하고 있어 변경이 필요 없었다(코드 확인 완료). 상세는 §1-9, `implementation-plan.md` Phase 7 항목.
> - v12: Phase 8(알림) 중 **Backend 인프라만** 실제로 구현했다(Flutter `notification` feature는 아직 없음 — 이번 범위 밖). `notifications`/`fcm_tokens` 테이블을 §4 설계 그대로 migration으로 작성: `notifications`는 `analysis_results`와 동일하게 select-only RLS(본인 `target_user_id`만, client insert/update/delete 정책 없음 — 쓰기는 `send-notification` Edge Function이 service_role로 수행). `fcm_tokens`는 §2-5 "FCM Token 보안"을 만족시키는 범위에서 본인 `user_id` 행만 select/insert/update 가능하도록 RLS를 붙였다(delete 정책은 없음 — 토큰 무효화 절차는 이번에 구현하지 않음, §5 OPEN QUESTIONS 참고). `send-notification` Edge Function을 신규 작성했다: 호출자(JWT로 검증)와 대상(`targetUserId`)이 `accepted` 상태의 `guardian_links`로 실제 연결되어 있는지 확인한 뒤에만 `notifications` row를 만들고, `fcm_tokens`에서 대상 사용자의 토큰을 조회해 FCM 발송을 시도한다(§1-10 "서버 키 사용" 원칙에 따라 legacy FCM HTTP API + 서버 키 사용). 이 환경에는 실제 Firebase 프로젝트/FCM 서버 키가 없어 발송 자체는 검증하지 못했다(`FCM_SERVER_KEY` 미설정 시 `pushSent: false, reason: "fcm_not_configured"`로 정직하게 응답) — migration/Edge Function 모두 정적 구조 검토만 완료(CLI 미설치로 실행 검증 불가). 상세는 `implementation-plan.md` Phase 8 항목.
> - **v13(이 버전)**: Phase 8 Guardian 프론트엔드를 실제로 구현했다(v12에서 "아직 없음"이라 적었던 부분 — `apps/guardian/lib/features/notification/` 3계층, FCM 토큰 lifecycle, 알림 목록, 딥링크). 통합 검증 중 발견한 두 개의 silent failure(클라이언트 `.update()`/`.delete()`가 RLS에 막혀 0건 처리되는데도 에러 없이 성공으로 보임)를 신규 migration(`20260814000004`)으로 수정했다: `read_at`은 `mark_notification_read(p_notification_id)` SECURITY DEFINER RPC로만 쓸 수 있게 하고(전체 UPDATE 정책은 열지 않음, `target_user_id = auth.uid()` 소유권 확인, 존재하지 않거나 타인 것이면 동일하게 `false` 반환), `fcm_tokens`에는 본인 행 한정 DELETE 정책을 추가했다. **Phase 7(위험 문자 AI 분석)을 실제로 구현했다** — 가장 중요한 미완료 지점이었다. `analyze-message` Edge Function(Anthropic Claude Messages API, tool-forced 구조화 출력 + 서버측 allowlist 재검증, §1-7 그대로 구현)을 신규 작성해 `MessageRiskRepositoryImpl`이 항상 `UnavailableFailure`를 반환하던 것을 실제 호출로 교체했다. 위험 판정(`caution`/`dangerous`) 시 `analyze-message`가 직접 `guardian_links`(accepted)를 조회해 대상 보호자를 결정한 뒤 `send-notification`을 호출한다 — client가 임의 `target_user_id`를 넣을 수 있는 경로는 만들지 않았다. 이 과정에서 **`send-notification`의 실제 버그를 하나 더 발견해 수정**했다: FCM `data` 블록에 `elder_id`/`analysis_result_id`가 빠져 있어 Guardian의 push-tap 딥링크(`resolveAndNavigateToAnalysisDetail`)가 항상 조용히 실패하고 있었다(인앱 알림 목록 tap은 `notifications.payload`를 따로 읽어 정상 동작했지만, 실제 푸시 배너를 탭하는 경로는 FCM `data`만 보므로 별도로 깨져 있었다). AI provider 시크릿은 `ANTHROPIC_API_KEY`(Supabase Edge Function secret)로 신규 문서화한다 — 이 환경에는 값이 없어 실제 AI 호출/실제 Supabase 연결(CLI·Docker·credentials 전부 없음)/실제 FCM 발송/실기기 E2E는 전부 **NOT AVAILABLE**로 기록한다(정적 코드 검토 + Dart mocktail 단위테스트만 완료, Deno 테스트 파일은 작성했으나 미실행). 상세는 `implementation-plan.md` Phase 8 항목.
> - v14: Phase 4(`document_scan`)의 AI 분석 백엔드 실제 연결 코드가 이전 세션에 이미 작성돼 커밋되지 않은 채 working tree에 남아 있었음을 확인하고, 이번 세션에는 실행 검증(`dart format`/`flutter analyze`/`flutter test`/`flutter build apk --debug`)과 이 v14 문서화를 수행했다(코드 작성 자체는 이번 세션 산출물이 아님 — `git log --follow` 근거는 `implementation-plan.md` v14 항목 참고). v8에서 골격만 만들고 "항상 `UnavailableFailure`"로 남겨뒀던 마지막 지점이 이 코드로 연결되어 있다. `analyze-document` Edge Function(Anthropic Claude Messages API, vision 입력 + tool-forced 구조화 출력, `analyze-message`와 동일 패턴)을 신규 작성했다. `document-photos` private Storage 버킷(migration `20260814000006`, `${auth.uid()}/<file>` 경로에 대한 owner-only INSERT RLS, SELECT/UPDATE/DELETE 정책 없음)을 추가해, 클라이언트가 본인 JWT로 사진을 업로드한 뒤 저장 경로만 Edge Function에 전달하도록 했다(§1-7/§1-8/§2 item 7 그대로 구현 — API 키도 원본 이미지 바이트도 함수 호출 페이로드에 오르지 않는다). Edge Function은 서비스 역할로 그 경로를 다운로드해 분석하고, 성공/실패 여부와 무관하게 `finally`에서 원본을 즉시 삭제한다(§1-8/§2 item 9 — 실패 시에도 orphan 업로드를 남기지 않음). `AnalysisRepositoryImpl`은 `analyze-message`와 동일한 reason-code → `Failure` 매핑(`missing_authorization`/`invalid_session`→`AuthFailure`, `invalid_storage_path`/`image_too_large`→`ValidationFailure`, `ai_provider_not_configured`→`UnavailableFailure`, 그 외 provider/서버 오류→`ServerFailure`)을 따른다. 기존 위젯 테스트(`document_scan_preview_page_test.dart`/`document_scan_result_page_test.dart`)는 실제 Supabase 의존이 생겨 `FakeAnalysisRepository` override로 조정했다(assertion은 그대로 유지 — 삭제/약화 아님, `message_check`의 v13 조정과 동일 패턴). Senior `analysis_repository_impl_test.dart` 신규 8개(성공/서버측 `ok:false`/reason별 `FunctionException` 매핑 5종/Storage 업로드 실패/미로그인/malformed 응답) 포함, `document_scan` 스위트 27개·Senior 앱 전체 122개 `flutter test` 통과, `dart format`/`flutter analyze` 통과. AI provider 시크릿은 `analyze-message`와 동일한 `ANTHROPIC_API_KEY`를 재사용한다(별도 키 신설 없음). 이 환경에는 값이 없어 실제 AI 호출/실제 Storage 업로드/실제 Supabase 연결은 여전히 **NOT AVAILABLE**(정적 코드 검토 + Dart mocktail 단위테스트만 완료, Deno 테스트 파일도 작성했으나 Deno CLI가 없어 미실행). 상세는 `implementation-plan.md` Phase 4 항목.
> - v15: Phase 9(UI 개선)를 실제로 구현했다. OPEN QUESTIONS 8번(쉬운 모드 하단 Navigation 변경 범위)을 "탭 구성은 유지, 스타일(아이콘/라벨)만 확대"로 DECIDED 처리했다(§5). 답변 신뢰도 UI는 Phase 4/7에서 이미 구현 완료돼 있어 재작업하지 않았다. `emergency_help`에 `url_launcher` 기반 `DialerRepository`/`CallPhoneUseCase`를 신규 추가해 119/112/118을 실제 다이얼러로 연결했다 — "보호자에게 전화"는 보호자 전화번호를 조회할 데이터 소스가 이 저장소에 없어(§4 `guardian_links`는 `guardian_id`만 보유) 가짜 연결 대신 정직한 준비중 안내로 남겼다. 완전히 비어 있던 `support` feature에 `SupportPage`/`PrivacyInfoPage`를 신규 구현했다 — 개인정보 보관 안내는 이 문서에서 이미 확정·구현된 정책만 서술하고, §5 OPEN QUESTIONS 5번(분석 결과 원문 보관 기간)처럼 미확정인 항목은 확정된 척하지 않는다. `design_system`에 `AppEasyMode` 토큰을 추가해 `AppBottomNavigation(large: true)`로 Easy Mode 하단 Navigation 스타일 확대를 구현했다. 테스트 작성 중 `EmergencyHelpSheet`의 실제 `RenderFlex overflow` 버그(테스트 부재로 지금까지 발견 못함)를 찾아 `SingleChildScrollView`로 수정했다. Senior `flutter test` 122→130개, `design_system` 신규 2개(이 패키지의 첫 테스트) 전부 통과, `dart format`/`flutter analyze`/`flutter build apk --debug` 통과. Guardian 앱은 이번 Phase 대상이 아니라 변경 없음. 상세는 `implementation-plan.md` Phase 9 항목.
> - v16: Phase 10(음성 비서)을 실제로 구현했다. §5 OPEN QUESTIONS 9~10을 사용자 확인 후 DECIDED 처리했다 — (9) STT/TTS는 온디바이스(`speech_to_text`/`flutter_tts`, 클라우드 서비스 채택 안 함), (10) 의도분류는 클라이언트 키워드 매칭(§1-7의 "AI 처리는 서버 경유" 원칙은 문자/문서 내용의 실제 위험·의미 판단에 적용되는 것이지, 음성 비서의 고정된 소수 명령을 온담 기능에 연결하는 것에는 해당하지 않는다고 판단). `apps/senior/lib/features/voice_assistant/`를 신규 구현: 마이크 권한은 `document_scan`의 `CameraPermissionStatus`/`CameraRepository` 구조를 그대로 미러링(`MicPermissionStatus`/`MicRepository`), 의도분류(`ClassifyVoiceIntentUseCase`)는 순수 Dart 키워드 매칭으로 서버 호출이 전혀 없다. STT/TTS 엔진은 `document_scan`의 `CameraPreviewView`가 `CameraController`를 직접 소유하는 것과 동일한 이유로 `VoiceInteractionView`(presentation)가 직접 소유한다. 지원 명령은 문서 촬영/문자 확인/긴급 도움 3개로 한정했다 — "경로당 찾아줘"는 `welfare_center` feature 자체가 비어 있어(`.gitkeep`만 존재) 제외했고, 명령이 늘거나 자유 발화가 필요해지면 그때 서버 AI 의도분류를 재검토하도록 신규 OPEN QUESTIONS 23번을 남겼다(§5). 인식 실패/무음은 하드 에러가 아니라 "다시 한번 말씀해주세요" 부드러운 재시도로 처리한다(ui-spec.md 그대로). Senior 신규 테스트 9개(`ClassifyVoiceIntentUseCase` 5, mic permission usecase 4) — `flutter test` 130→139개 통과. `VoiceAssistantPage`/`VoiceInteractionView`는 플랫폼 채널(STT/TTS) 의존으로 `document_scan_camera_page`/`CameraPreviewView`와 동일하게 위젯 테스트를 작성하지 않았다(선례와 일관). `dart format`/`flutter analyze`/`flutter build apk --debug` 통과(빌드 로그에 `flutter_tts`/`speech_to_text`의 Kotlin Gradle Plugin 구버전 적용 방식 경고가 있으나 빌드는 성공 — 차단 아님). 이 환경에 Android/iOS 실기기가 없어 실제 한국어 음성 인식/TTS 발화/마이크 권한 프롬프트는 **NOT AVAILABLE**. Guardian 앱은 이번 Phase 대상이 아니라 변경 없음. 상세는 `implementation-plan.md` Phase 10 항목.
> - **v17(이 버전)**: Phase 11(통합 테스트 및 안정화)을 실제로 구현했다. 안정화 점검 중 실제 버그를 하나 발견해 수정했다 — Senior/Guardian 양쪽 `PinNotifier.deleteAccount()`가 성공 후 `pinVerifiedProvider`만 리셋하고 로컬 Supabase 세션(`signOut`)은 끝내지 않고 있었다. 계정은 서버에서 이미 삭제됐지만 로컬 세션이 남아 있으면 라우터의 `hasSession` 게이트가 여전히 참이 되어, 존재하지 않는 계정을 위한 PIN 입력 화면으로 보낼 수 있는 상태였다 — 양쪽 모두 성공 시 `signOutUseCase`를 함께 호출하도록 수정했다. 같은 점검에서 `TextStyle(color: AppColors.error)` 형태의 하드코딩 4건(양쪽 앱 `settings_page.dart`의 "회원 탈퇴", Senior `guardian_list_page.dart`/Guardian `connection_list_page.dart`의 "연결 해제")을 발견해 `AppTextStyles.xxx.copyWith(color:)`로 교체했다(ui-design.md 규칙 위반 — 신규 코드가 아니라 기존 코드에 남아 있던 것). `design_system`의 `AppConfirmDialog`에도 같은 패턴이 하나 더 있으나, 이 컴포넌트는 여러 feature가 공유하고 원래 `TextStyle(color: destructive ? error : null)`이 "테마 기본 스타일은 유지하고 색상만 오버라이드"를 의도적으로 하고 있어(page-level 4건과 달리 null 분기가 의미 있음) 시각적 회귀 위험이 있다고 판단해 이번에는 건드리지 않고 기록만 남긴다. **§2 item 10(계정 탈퇴 시 연결/데이터 삭제 정책) 정적 검증**: 모든 사용자 소유 테이블에 `on delete cascade`가 실제로 걸려 있음을 마이그레이션 리뷰로 확인했으나, "보호자 쪽에 안내만 남기고"는 cascade가 레코드 자체를 지워버려 구현되어 있지 않음을 발견 — 신규 OPEN QUESTIONS 24번으로 남기고 이번에 임의로 설계·구현하지 않았다(제품 결정 필요). **통합 테스트 신규 작성**: `test/integration/`(양쪽 앱 신규 디렉터리) — 계정 탈퇴 흐름(설정→확인 다이얼로그→탈퇴, 방금 고친 버그의 회귀 테스트) 2세트, 보호자 연결 수락/거절/해제 흐름(지금까지 domain usecase 단위 테스트만 있고 화면 단위 테스트가 없던 gap) 2세트. `go_router`의 `hasSession` 게이트가 `Supabase.instance.client.auth.currentSession`을 직접 읽어 fake로 override할 수 없어(의도된 설계 — 세션 검증을 순수 클라이언트 상태로 우회할 수 없게 함) OTP+PIN 가입 전체를 관통하는 진짜 end-to-end 라우터 테스트는 이 환경에서 구조적으로 **NOT AVAILABLE**임을 확인했다 — 대신 인증이 필요 없는 화면을 직접 마운트하는 기존 프로젝트 관례(`message_check_navigation_test.dart` 등)를 그대로 따랐다. Senior `flutter test` 139→144개, Guardian 100→105개(v13 기준 100에서 신규 5개 추가) 모두 통과. `dart format`/`flutter analyze`(양쪽 0 issue)/`flutter build apk --debug`(양쪽 성공) 통과. "보호자 연결요청→위험문자→Push알림"의 실제 크로스앱 E2E와 음성 비서 실기기 동작은 이 환경에 실 Supabase/FCM/AI 키/실기기가 없어 지금까지와 동일하게 **NOT AVAILABLE**. 상세는 `implementation-plan.md` Phase 11 항목.
>
> 함께 읽는 문서: `docs/product/implementation-plan.md`(Phase별 실행 계획), `docs/product/feature-spec.md`, `docs/architecture/architecture.md`, `docs/ui/ui-spec.md`.

---

## 0. 확정 요약표

| # | 항목 | 확정 내용 |
|---|---|---|
| 1 | Backend | **Supabase** (커스텀 서버 미사용) |
| 2 | Database | **PostgreSQL** (Supabase 기본 제공) |
| 3 | 인증 | **전화번호 + OTP(가입 시) + PIN(평상시 로그인)**, 중요 작업(보호자 연결/계정 복구/보안정보 변경)에 추가 인증. **PIN 검증은 100% Backend Edge Function 담당(B안), Session은 Supabase 표준 유지 — 상세 §1-3-A** |
| 4 | 보호자 알림 | **Push(FCM) 기본 + 서버에 알림 상태 저장**, SMS는 보조 수단으로 확장 가능하게 설계만 |
| 5 | 어르신-보호자 관계 | **어르신 1 : 보호자 N (1:N) 기본**, DB는 관계 테이블로 N:M 확장 여지를 막지 않음 |
| 6 | 보호자 연결 인증 | **어르신 수락(승인) 방식** — 전화번호만으로 즉시 연결 금지. 요청 트리거는 **QR 코드**(서버 발급 단기 유효 토큰, PII 미포함) — v9 확정, §1-6 |
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
- PIN 자체의 저장/검증 메커니즘, Supabase Auth Session과의 결합 방식은 아래 **§1-3-A**에서 확정한다(구 OPEN QUESTIONS 1번).

### 1-3-A. OTP+PIN+Supabase Auth Session 결합 방식 — 확정 (구 OPEN QUESTIONS 1번)

> 이 절은 Phase 2(Authentication) 착수 전 `technical-decisions.md` OPEN QUESTIONS 1번을 해소하기 위해 별도로 설계한 세부 Architecture다. §5에서는 이 항목을 `DECIDED`로 표시하고 상세 내용은 이 절을 가리킨다.

#### 최종 선택: **B안 — PIN 검증을 100% Backend(Edge Function)에서 관리**

A안(PIN을 앱 로컬 인증으로만 처리)은 기각한다. 4자리 PIN은 경우의 수가 10,000가지뿐이라, PIN 해시를 기기에 저장해두고 로컬에서 비교하는 순간 — 기기가 탈취/루팅되면 오프라인 무차별 대입에 사실상 무방비가 된다(느린 해시 알고리즘을 써도 10,000번은 금방 끝난다). C안(PIN 전용 별도 인증 레이어 신설)은 이번 단계에서는 과설계로 판단 — 아래 설계의 "앱 재진입 게이트"가 C안이 주려는 이점(세션이 살아있어도 재인증 요구)을 별도 토큰 시스템 없이도 충분히 제공한다.

#### 핵심 원칙: Session과 PIN은 완전히 분리된 두 개념이다

| 개념 | 정체 | 수명주기 | 저장 위치 |
|---|---|---|---|
| **Supabase Auth Session** | 표준 GoTrue access/refresh token | Supabase SDK가 표준대로 관리(발급/자동갱신/만료) — 앱이 이 동작에 개입하지 않는다 | 각 앱의 Secure Storage(SDK 내부 위임) |
| **PIN 상태** | "지금 이 사람이 이 세션을 써도 되는가"를 매번 재확인하는 앱 자체 게이트 | 앱을 새로 열 때마다(cold start) 또는 idle timeout 경과 후 **항상 초기화**됨 — 로컬에 "PIN 확인됨" 상태를 영속화하지 않는다 | `pinVerifiedProvider`(각 앱의 인메모리 Riverpod 상태, `core/storage`가 아닌 순수 메모리 — **디스크에 저장 금지**) |

이 둘을 절대 같은 저장소/같은 토큰으로 섞지 않는다(사용자 원칙 7을 문자 그대로 구현).

#### 흐름 1 — 최초 가입

```
전화번호 입력
  ↓
Supabase Phone OTP 발송(auth.signInWithOtp)
  ↓
OTP 코드 검증(auth.verifyOtp) → Supabase Auth 유저 생성 + Session 발급(Supabase 표준 동작)
  ↓
PIN 설정 화면 (이미 유효한 Session이 있으므로 Authorization 헤더로 신원 증명됨)
  ↓
클라이언트 → `set-pin` Edge Function 호출 (평문 PIN 전송, HTTPS)
  ↓
Edge Function: auth.uid()로 본인 확인 → DB 함수 호출(pgcrypto로 PIN을 bcrypt 해시, v6 확정) → `pin_credentials` 테이블에 저장
  ↓
가입 완료. `pinVerifiedProvider = true`로 세팅(방금 본인이 설정했으므로), 온보딩 계속 진행
```

#### 흐름 2 — 앱 재진입(이미 로그인된 기기, Session은 로컬에 유효)

```
앱 실행(cold start) 또는 idle timeout 경과
  ↓
라우터 가드: Supabase SDK에 유효한 Session이 있는가? → 있음
  ↓
라우터 가드: `pinVerifiedProvider`가 true인가? → **항상 false**(재실행 시 초기화됨) → PIN 입력 화면으로 이동
  ↓
사용자가 PIN 입력 → 클라이언트 → `verify-pin` Edge Function 호출 (phone 또는 auth.uid() + PIN)
  ↓
Edge Function: `pin_credentials`에서 lockout 상태 확인 → 해시 비교
  ├── 실패 → failed_attempts 증가, 필요 시 locked_until 설정, 401 반환
  └── 성공 → failed_attempts 리셋, 200 반환
  ↓
클라이언트: 200 응답 받으면 `pinVerifiedProvider = true`로 세팅 → 게이트 해제, 홈 화면 진입
```

**세션 자체는 다시 발급받지 않는다** — 이미 SDK가 들고 있는 Session을 그대로 쓴다. `verify-pin`은 오직 "PIN이 맞는지"만 서버에서 확인해줄 뿐이다. 이 설계 덕분에 PIN 무차별 대입은 반드시 이 Edge Function을 거쳐야 하고, `pin_credentials.failed_attempts`/`locked_until`은 클라이언트가 건드릴 수 없는 서버 측 상태이므로 우회 불가능하다(사용자가 지적한 "PIN brute force via API" 위협에 대한 직접적 방어).

#### 흐름 3 — 새 기기 로그인

```
전화번호 입력(새 기기 — 로컬에 Session 없음)
  ↓
라우터 가드: 유효한 Session 없음 → OTP 화면으로 강제 이동(PIN 화면으로 가지 않음, 검증할 로컬 세션이 없으므로 무의미)
  ↓
Supabase Phone OTP 발송/검증 → 기존 phone에 매칭되는 기존 Supabase Auth 유저로 Session 발급(Supabase가 phone 기준 기존 유저 인식)
  ↓
기존 PIN 그대로 유효(서버의 `pin_credentials`에 이미 저장되어 있으므로) — "기존 PIN 입력" 또는 "새 PIN으로 재설정" 중 선택 제공
  ↓
어느 쪽이든 통과하면 `pinVerifiedProvider = true`, 새 기기의 Secure Storage에 새 Session(refresh token) 저장
```

#### 흐름 4 — PIN 분실

```
로그인 화면의 "PIN을 잊으셨나요?"
  ↓
전화번호 확인 → Supabase Phone OTP 재발송/검증(원칙 6: 보안상 중요한 상황의 OTP 재검증)
  ↓
성공 → `reset-pin` Edge Function 호출 → 새 PIN 설정, 기존 pin_hash 덮어씀, failed_attempts/locked_until 초기화
```

#### 흐름 5 — 로그아웃

```
클라이언트: `pinVerifiedProvider`를 false로 리셋
  ↓
Supabase `auth.signOut()` 호출 → 서버가 refresh token을 명시적으로 revoke(rotating refresh token이므로 재사용 탐지도 됨)
  ↓
Secure Storage에서 Session 관련 캐시 정리(SDK가 관리하는 영역 포함)
```

#### 흐름 6 — 계정 탈퇴

```
`delete-account` Edge Function(서비스 롤 권한으로 실행)
  ↓
`pin_credentials` row 삭제 + `user_roles` row 삭제 + auth.admin.deleteUser() 호출
  ↓
연쇄 삭제: guardian_links/analysis_results/schedules 등은 FK ON DELETE CASCADE 또는 명시적 삭제(§2-10 정책과 동일)
```

#### PIN 정책 확정값

- **자릿수**: 4자리 숫자 유지(기존 앱 UX, 고령층 접근성 고려 — KEEP-1과 일관). 브루트포스 방어는 자릿수가 아니라 서버 lockout으로 확보한다.
- **해시**: **bcrypt(pgcrypto) — v6에서 Argon2id에서 변경 확정. 근거는 아래 "PIN 해시 알고리즘 기술 검증(구 OPEN QUESTIONS 16)" 참고.**
- **앱 재진입 idle timeout**: Senior 15분 / Guardian 5분 — v6 확정. 근거는 아래 "앱 재진입 idle timeout(구 OPEN QUESTIONS 17)" 참고.
- **잠금 정책**: 5회 연속 실패 → 5분 잠금. 추가 5회(누적 10회) → 30분 잠금. 이후 실패마다 지수 백오프(최대 24시간) 또는 OTP 재인증 강제 전환. 성공 시 `failed_attempts` 즉시 리셋.
- **저장 위치**: `pin_credentials` 전용 테이블. `users`(프로필) 테이블과 분리하고, 클라이언트/anon/authenticated 어떤 role도 이 테이블에 직접 SELECT/INSERT/UPDATE 권한을 갖지 않는다(RLS로 전면 차단, 오직 서비스 롤을 쓰는 Edge Function만 접근) — §2-3 RLS 원칙과 동일한 defense-in-depth.
- **클라이언트 로컬 저장**: PIN 원문·해시 어느 것도 클라이언트에 저장하지 않는다(로컬 저장소에는 PIN에 관한 어떤 파생값도 남기지 않음 — 사용자 요구 "평문 저장 금지, 단순 암호화만 해서 저장하는 방식도 사용 안 함"을 가장 강하게 만족하는 방법은 **저장 자체를 안 하는 것**).

#### Session ↔ PIN 상태를 분리 유지하는 구현 지침

- Supabase SDK의 자동 토큰 갱신(autoRefreshToken)은 표준 설정 그대로 둔다 — 이 동작을 앱이 막거나 흉내내지 않는다.
- "PIN 게이트"는 순수하게 **화면 접근 제어**로 구현한다: 각 앱의 `app/router/`에 `redirect` 콜백을 추가해 `hasValidSession && !pinVerified`이면 PIN 입력 화면으로, `!hasValidSession`이면 로그인(전화번호) 화면으로 보낸다. Backend API 호출 권한 자체(RLS)는 Session만으로 이미 정상 동작하므로 건드리지 않는다 — PIN 게이트는 "UI 접근"만 막는 앱 차원의 추가 안전장치다.
- `pinVerifiedProvider`는 `autoDispose` 없이 앱 최상위 `ProviderScope` 수명과 함께하되, **앱 프로세스가 재시작되면 무조건 초기값(false)**이어야 한다 — 즉 어떤 형태로든 디스크에 캐시하면 안 된다(`riverpod.md`의 "화면 하나에서만 쓰는 상태는 전역 Provider로 만들지 않는다" 원칙과 다른 이유로 keepAlive를 쓰되, 영속화는 명시적으로 금지).

#### PIN 해시 알고리즘 기술 검증 — 확정 (구 OPEN QUESTIONS 16, v6)

> 웹 조사로 실제 Supabase Edge Function 환경에서의 운영 가능성을 확인한 결과다(공식 문서/GitHub 기준, 아래 근거 참고).

**확인된 사실**:
1. **Supabase Edge Function은 요청당 CPU 시간이 최대 2초, 메모리 256MB로 제한된다**(Supabase 공식 Limits 문서). 이는 요청 처리 전체(파싱/DB 조회/해시 계산 등)에 대한 예산이며, Argon2id 같은 메모리 하드 KDF를 OWASP 권장 파라미터(예: m=19~47MB, t=1~2)로 계산하면 WASM 실행 오버헤드(네이티브 대비 통상 2~5배 느림) + cold start 시 WASM 모듈 컴파일 비용까지 겹쳐 이 예산에 근접하거나 초과할 위험이 실측 없이는 배제되지 않는다.
2. **Deno 생태계의 "검증된" Argon2 라이브러리(`deno.land/x/argon2`)는 네이티브 플러그인(FFI, `--allow-plugin` 필요) 방식**이다 — Supabase의 샌드박스형 Edge Runtime은 이런 임의 네이티브 플러그인 로딩을 허용하지 않을 가능성이 매우 높아(다중 테넌트 보안 격리가 핵심 설계 목표이므로), 사실상 배제된다.
3. **순수 WASM 기반 Argon2 대안**(`argontwo`, `hash-wasm`, `openpgpjs/argon2id`)은 기술적으로 `npm:` 임포트를 통해 동작할 여지가 있으나: `argontwo`는 커밋 9개뿐으로 유지보수 신호가 약함, `hash-wasm`은 최종 릴리즈가 약 2년 전으로 정체 상태, `openpgpjs/argon2id`가 그나마 가장 활발하고 신뢰할 만한 조직(OpenPGP.js)이 유지하는 옵션이나 **Supabase Edge Function 환경에서의 실사용 사례/벤치마크가 공개적으로 확인되지 않는다**.
4. **Supabase 자신도 자사 Auth(GoTrue)의 비밀번호 해시에 bcrypt를 쓴다**(공식 문서 확인). 커뮤니티의 "Edge Function에서 커스텀 인증 구현" 예제들도 일관되게 `bcrypt`/`bcrypt.compare`를 사용한다 — 이는 실제로 이 정확한 시나리오(Edge Function에서 자체 자격증명 해시 검증)에서 검증된 실무 패턴이다.
5. **PostgreSQL의 `pgcrypto` 확장은 `crypt()`/`gen_salt('bf', ...)`로 bcrypt를 네이티브(C) 속도로 지원한다.** Argon2는 지원하지 않는다.

**결론(확정)**: **Argon2id 대신 bcrypt를 채택한다.** 더 나아가, 해시 계산 자체를 Edge Function(Deno/WASM)이 아니라 **PostgreSQL의 `pgcrypto` 확장을 사용하는 `SECURITY DEFINER` DB 함수**(`set_pin(uid, pin)`, `verify_pin(uid, pin)` 등)로 구현할 것을 권장한다. 이렇게 하면:
- Deno/WASM Argon2 라이브러리의 유지보수·호환성 리스크를 원천적으로 제거.
- 해시 계산이 Edge Function의 2초 CPU 예산과 무관하게 Postgres 엔진 내부(C로 컴파일된 확장)에서 실행되어 타임아웃 리스크가 사라짐.
- Edge Function(`set-pin`/`verify-pin`/`reset-pin`)은 얇은 오케스트레이션 계층(요청 검증, lockout 카운터 조회, DB 함수 호출, 세션 관련 응답 구성)으로 단순해짐.
- Supabase 자신의 내부 구현(bcrypt)과 일치해 향후 유지보수 부담이 낮다.

**PIN이 4자리라는 점에서 이 선택이 안전한 이유**: PIN 브루트포스 방어의 1차 방어선은 애초에 해시 알고리즘의 계산 비용이 아니라 **서버 측 lockout 정책**(§ "PIN 정책 확정값")이다. Argon2id의 우위(GPU/ASIC 병렬화 저항)는 키 공간이 큰 일반 비밀번호에서 두드러지는데, PIN의 키 공간은 애초에 10,000가지뿐이라 그 우위가 상대적으로 작다. 반대로 bcrypt는 cost factor(예: 10~12)로 offline 대입 시간을 의미 있게 늘리면서도(수백ms/회) Edge Function 예산 안에서 예측 가능하게 동작한다는 실무적 이점이 훨씬 크다.

**대체안 비교(참고)**:

| 기준 | Argon2id(WASM) | **bcrypt via pgcrypto — 채택** | PBKDF2 |
|---|---|---|---|
| Supabase Edge Function 호환성 | 불확실(벤치마크 없음, 2초 CPU 예산 리스크) | **확실(Postgres 네이티브, Edge Function 예산과 무관)** | 확실(가볍지만 반복 횟수 낮으면 약함) |
| 라이브러리 유지보수 | 약함~보통(후보들 대부분 정체) | **강함(Postgres 코어 확장, 수십 년 검증)** | 강함(표준 라이브러리 수준) |
| PIN(4자리) 시나리오 적합성 | 과설계(이점이 서버 lockout에 가려짐) | **충분(cost factor로 조절 가능)** | 충분하나 업계 권장도가 bcrypt보다 낮음 |
| 구현 난이도 | 높음(WASM 임포트+벤치마크+파라미터 튜닝 필요) | **낮음(SQL 함수 몇 줄)** | 낮음 |

#### 앱 재진입 idle timeout — 확정 (구 OPEN QUESTIONS 17, v6)

- **Senior App: 15분.** 고령 사용자는 전화를 받거나 TV를 보는 등 앱을 잠깐 두고 자리를 뜨는 일이 잦다 — 너무 짧은 timeout(1~5분)은 정상 사용 흐름에서도 PIN을 자주 요구해 "평상시엔 OTP 없이 PIN만" 원칙의 접근성 취지를 해친다. 그렇다고 30분 이상은 분실/방치된 기기의 노출 시간을 과도하게 늘린다. 일반적인 모바일 뱅킹 앱들의 idle timeout 관행(5~15분)과도 정합되는 15분을 기본값으로 채택.
- **Guardian App: 5분.** 보호자는 상대적으로 기기 조작에 익숙하고, 부모의 민감한 개인정보(위험 문자 원문, 연락처 등)를 다루므로 Senior 앱보다 짧게 재확인한다.
- 두 값 모두 **Phase 2에서는 고정값**으로 시작한다. 사용자가 값을 직접 조정할 수 있게 설정 UI를 제공할지는 이번에 다루지 않는 후속 개선사항으로 **OPEN QUESTIONS 19**에 남긴다.

#### Guardian 생체인증 — OPEN 유지 (구 OPEN QUESTIONS 18, v6)

**Phase 2 범위에는 포함하지 않는다.** 이유:
- 생체인증(FaceID/TouchID/Android BiometricPrompt)이 성공했을 때 앱이 실제로 "무엇을 서버에 제출해 세션을 언락할지"가 문제다. PIN 자체를 로컬에 캐시해뒀다가 생체인증 성공 시 자동 제출하는 방식은 "PIN을 로컬에 저장하지 않는다"는 원칙 4를 정면으로 위반한다.
- 이를 피하려면 PIN과 별개로 "생체인증으로 보호되는 별도의 장기 device credential"을 새로 설계해야 하는데, 이는 사실상 새 자격증명 체계를 하나 더 만드는 것이라 B안 대비 복잡도가 C안에 가까워진다. 지금 시점에 Guardian 생체인증 하나를 위해 들일 복잡도로는 정당화하기 어렵다고 판단.
- `local_auth`(Flutter 공식 지원 패키지)로 Android/iOS 구현 자체의 난이도는 낮으므로, 향후 "PIN 대신"이 아니라 "PIN 검증 요청을 로컬에서 트리거하는 편의 기능"(여전히 서버 `verify-pin` 호출은 필요, 별도 device credential 발급 포함)으로 재설계해 추가하는 것은 유효한 후속 과제로 남긴다.
- **Status: OPEN.** 기술적으로 불가능하지 않지만, 이번 Phase 2에서 결정할 문제가 아니라 별도 설계 라운드가 필요하다.

#### Role 관리 — "앱 이름으로 role을 신뢰하지 않는다" (구 OPEN QUESTIONS 15 — 확정, v6)

- `auth.users`(Supabase Auth)는 Senior/Guardian 두 앱이 **공유하는 단일 사용자 풀**이다 — 전화번호가 유일 식별자이며, 앱과 무관하게 같은 전화번호는 같은 `auth.users` row로 귀결된다.
- Role은 앱 종류가 아니라 **`user_roles` 테이블**(신규, `user_id`, `role`— `elder`/`guardian`, 복수 row 허용)이 진실의 원천이다. 온보딩에서 "저는 어르신입니다/보호자입니다"를 선택하면 해당 row가 INSERT된다.
- 데이터 접근 RLS 정책은 **요청이 어느 앱 번들에서 왔는지를 절대 신뢰하지 않고**, 항상 `user_roles`에 실제로 해당 role이 존재하는지로 권한을 검사한다(예: `guardian_links`에 보호자로서 쓰기 작업을 하려면 RLS가 `auth.uid()`가 `user_roles`에 `role='guardian'`으로 있는지 확인).
- **확정(B안 — 동시 허용)**: 동일 전화번호가 Senior/Guardian 양쪽 role을 동시에 가질 수 있도록 허용한다. 근거:
  - `user_roles`를 이미 N:M 구조로 설계해뒀다(A안을 택하려면 오히려 "전화번호당 1 role" 제약을 역으로 추가해야 해 이미 만든 구조를 좁히는 방향).
  - 실사용에서 "부모님 기기를 설정해주다가 실수로 본인 번호로 어르신 앱에 가입"처럼 앱을 잘못 사용하는 상황이 드물지 않다 — A안(원천 차단)은 이런 상황에서 사용자가 스스로 복구하기 어려운 막다른 골목을 만든다. B안(허용)은 이런 실수를 온보딩 안내로 부드럽게 처리할 수 있다.
  - 향후 관리자 시스템 관점에서도 "한 사용자가 여러 role을 가질 수 있다"는 데이터 모델이 예외 케이스가 아니라 정상 케이스로 다뤄지는 편이 더 유연하다.
  - **온보딩 UX 보완**: 이미 다른 role로 가입된 전화번호로 새 앱에 가입을 시도하면 완전히 막지 않되 "이 번호는 이미 온담 [어르신/보호자] 앱에 가입되어 있어요. 계속 진행하시겠어요?" 같은 안내를 표시한다(무음 허용도, 완전 차단도 아닌 절충).
  - **자기 자신을 보호자로 연결하는 어뷰징 방지**: `guardian_links` 생성 시 `elder_id != guardian_id`를 애플리케이션/DB 제약(CHECK 제약 또는 트리거)으로 명시적으로 막는다 — B안 채택에 따라 새로 필요해진 유일한 추가 제약.

#### A/B/C 비교

| 기준 | A안(로컬 인증) | **B안(서버 관리) — 채택** | C안(별도 인증 레이어) |
|---|---|---|---|
| 보안(브루트포스) | 취약(기기 탈취 시 오프라인 대입 무방비) | **강함(서버 lockout으로 원천 차단)** | 강함(단, B안과 동일한 서버 검증이 필요해 결국 B안을 포함) |
| Session 탈취 방지 | Session과 PIN 개념이 얽히기 쉬움 | **완전 분리(원칙 7 충족)** | 완전 분리(추가 토큰 레이어로 더 복잡하게 분리) |
| UX | 오프라인에서도 빠름 | 매 재진입마다 네트워크 필요(단, 응답 매우 가벼움) | A/B와 동일하거나 더 느림(레이어 추가) |
| 구현 난이도 | 낮음 | **중간**(Edge Function 3~4개 필요) | 높음(별도 토큰 발급/검증 시스템 신설) |
| Supabase와의 궁합 | 좋음(로컬 완결) | **좋음**(Supabase 표준 Session은 그대로, PIN만 별도 관리) | 보통(Supabase Session과 별개로 자체 토큰 체계를 유지해야 해 이중 관리 부담) |
| Senior App 적합성 | 보통(오프라인 진입은 빠르나 보안 취약이 더 치명적 — 고령층 대상일수록 피싱/탈취 피해에 취약) | **좋음** | 좋음(과설계 대비 이득 적음) |
| Guardian App 적합성 | 보통 | **좋음** | 좋음(과설계 대비 이득 적음) |
| 새 기기 대응 | 별도 설계 필요(로컬 해시가 없으므로 사실상 OTP로 우회) | **자연스러움**(OTP 재인증 후 기존 PIN 그대로 유효) | 자연스러움(B안과 동일 메커니즘 필요) |
| PIN 분실 대응 | 로컬 초기화만 가능, 서버와 정합성 깨지기 쉬움 | **OTP 재인증 → 서버 PIN 재설정으로 깔끔** | 동일 |
| 계정 탈퇴 대응 | 로컬 삭제만으로는 서버 데이터 잔존 위험 | **서버가 진실의 원천이므로 삭제도 서버가 원자적으로 처리** | 동일 |
| 향후 관리자 시스템 확장성 | 무관 | **무관 — 관리자 인증은 완전히 별도 경로(예: 이메일+비밀번호)로, 이 결정과 독립적** | 무관(동일) |

**결론**: C안이 주는 이점(세션이 살아있어도 재인증)은 B안의 "앱 재진입 게이트"로 별도 토큰 시스템 없이 동일하게 달성되므로, B안 대비 C안의 추가 복잡도를 정당화할 이유가 없다. B안을 최종 채택한다.

#### Phase 2 구현 완료 요약 (v7)

위 설계가 실제로 어떻게 구현됐는지 기록한다. 설계 자체(B안, bcrypt/pgcrypto, lockout 정책, idle timeout 값 등)는 변경되지 않았다 — 아래는 "실제로 그 설계를 어떤 파일/구조로 옮겼는지"의 기록이다.

**DB migration (`supabase/migrations/`, 4개, 순서대로 적용)**
1. `20260812000001_create_user_roles.sql` — `user_roles` 테이블 + RLS(본인 행만 select/insert).
2. `20260812000002_create_pin_credentials.sql` — `pgcrypto` extension 활성화 + `pin_credentials` 테이블. RLS 활성화 상태로 `authenticated`/`anon`/`public` 모든 grant를 revoke — 클라이언트의 직접 접근이 RLS 정책 부재가 아니라 이중으로(RLS + grant revoke) 차단됨.
3. `20260812000003_pin_functions.sql` — `set_pin`/`verify_pin`(설계대로) + **`has_pin`(설계 문서에는 없던 추가 함수)**. `has_pin(uid) returns boolean`은 PIN 해시 자체는 절대 노출하지 않고 "PIN이 설정되어 있는가"만 반환한다 — 라우터가 PIN 설정 화면과 PIN 입력 화면 중 어디로 보낼지 결정하는 데 필요해서 구현 중 추가했다. 세 함수 모두 EXECUTE는 `service_role`에만 부여.
4. `20260812000004_create_guardian_links.sql` — `guardian_links` 테이블 + `elder_id <> guardian_id` CHECK 제약(설계대로) + 본인 관련 행 select RLS만. INSERT/UPDATE(연결 요청·수락·거절·해제) 정책은 의도적으로 이번 범위에 넣지 않았다 — `connection` 기능은 Phase 5이므로, 그 기능의 migration에서 추가한다.

**Edge Functions (`supabase/functions/`, 5개)**: `set-pin`/`verify-pin`/`reset-pin`/`delete-account`(설계된 최소 4개) + **`has-pin`**(위 `has_pin` DB 함수를 감싸는 얇은 오케스트레이션, 라우터 지원용으로 신규 추가). 공통 `_shared/{cors.ts, http.ts, auth.ts}`. `auth.ts`의 `verifyCaller()`가 설계된 "anon 클라이언트로 신원 확인 → service-role 클라이언트로 특권 RPC 호출" 2단계 패턴을 구현한다. `reset-pin`은 설계대로 `last_sign_in_at` 10분 이내 여부를 추가로 검사한다.

**Flutter 구현 (양쪽 앱 동일 구조 — `apps/senior`, `apps/guardian` 각자 독립적으로 전체 구현, 서로 import하지 않음)**
- `core/auth/`: `supabase_client_provider`(Supabase.instance.client를 Riverpod에 노출), `auth_state_provider`(Supabase Auth 상태 스트림), `pin_verified_provider`(메모리 전용 PIN 게이트), `auth_constants`(idle timeout 상수), `idle_timeout_controller`(`AppLifecycleListener` 기반, `shouldRelock()` 순수 함수로 분리해 유닛 테스트 가능하게 함).
- `features/auth/domain/`: `entities/pin_verify_result.dart`, `repositories/auth_repository.dart`(추상), `usecases/`(OTP 요청/검증, PIN 설정/검증/재설정, 계정탈퇴, role 추가/조회, sign-out — 9개), `utils/phone_number_formatter.dart`(한국 휴대폰 번호 → E.164 정규화).
- `features/auth/data/`: `datasources/auth_remote_datasource.dart`(Supabase Auth SDK + `user_roles` 테이블 직접 호출), `datasources/pin_remote_datasource.dart`(`SupabaseClient.functions.invoke`로 Edge Function 호출), `repositories/auth_repository_impl.dart`(SDK 예외 → domain `Failure` 매핑 — `api.md`의 "DataSource는 원본 예외를 던지고 Repository가 변환" 규칙을 Dio 대신 Supabase SDK 예외에 맞게 적용).
- `features/auth/presentation/`: DI wiring(`auth_di_providers.dart`), `OtpNotifier`/`PinNotifier`/`RoleNotifier`(모두 `AsyncNotifier`, `riverpod.md`의 "AsyncValue로 노출, 수동 isLoading/error 금지" 준수), `hasPinProvider`(라우터 지원 캐시), 화면 7개(phone_input/otp_verify/pin_setup/pin_entry/pin_forgot/role_select/session_loading), `widgets/pin_keypad.dart`(feature-local — Senior는 큰 버튼 76px, Guardian은 표준 크기 56px, 디자인 토큰만 사용).
- `packages/core`에 `Result<T>`(`Ok`/`Err`) 추가 — 이 프로젝트에는 `dartz`/`fpdart`가 없어 `api.md`의 "Either 또는 이에 준하는 명시적 성공/실패 표현" 요구를 충족하는 최소 구현. `packages/models`에 `UserRole` enum 추가.
- 라우터(`app/router/app_router.dart`)는 리다이렉트 판단 로직을 `app/router/auth_redirect.dart`의 순수 함수 `decideAuthRedirect()`로 분리해 Supabase/Riverpod 없이 유닛 테스트 가능하게 했다. 상태: No Session → phone/OTP, Session+PIN 미설정 → PIN 설정, Session+PIN 설정+미검증 → PIN 입력, Session+PIN 검증+role 없음 → role 선택, 그 외 → home(Phase 3 placeholder).

**설계 대비 변경/보완 사항**: (1) `has_pin` DB 함수 + `has-pin` Edge Function을 설계에 없던 것으로 추가(§4 데이터 모델에는 없었음, 순수 조회이므로 보안 영향 없음). (2) Role 선택 화면(`role_select_page`)을 신규 가입 흐름의 필수 단계로 라우터에 넣었다 — §1-3-A "Role 관리"의 "온보딩에서 선택" 문구를 실제 라우팅 단계로 구체화한 것.

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

### 1-6. 보호자 연결 인증 — QR 코드 기반 어르신 수락 방식 확정 (v9, 구 OPEN QUESTIONS 2번)

```
어르신: "보호자 연결" 화면 진입 → 서버가 단기 유효(수 분) 1회성 연결 토큰 발급 → QR로 표시
  ↓ ("보호자에게 이 QR을 보여주세요")
보호자: "어르신 연결하기" → QR 스캔 → 토큰을 서버로 전달
  ↓
서버: 토큰 유효성(미사용/미만료) + elder_id != guardian_id 검증
  → guardian_links에 pending 상태로 연결 요청 생성
  ↓
어르신 앱: "OO님이 보호자 연결을 요청했습니다" 표시 → 어르신이 확인 → 수락(accepted) 또는 거절(rejected)
  ↓
연결 완료(accepted) — 이후 보호자 앱은 공유 허용 정보만 RLS로 제한 조회
```

- **전화번호 직접 입력, 연결 코드 직접 입력은 기본 연결 방식으로 채택하지 않는다** — v9에서 OPEN QUESTIONS 2번을 **QR 코드 기반**으로 DECIDED 처리했다(구 초안에 있던 "전화번호 또는 연결 코드" 문구는 폐기).
- QR에는 전화번호/이름 등 개인정보나 추측 가능한 `user_id`를 직접 담지 않는다. 서버가 발급한 **단기 유효·1회성 연결 토큰** 문자열만 담는다.
- **QR 스캔 성공 ≠ 연결 완료.** 스캔은 pending 연결 요청을 생성하는 트리거일 뿐이며, `accepted`가 되려면 반드시 어르신 본인의 명시적 승인을 거쳐야 한다(§1-5 필수요구사항 3 "보호자가 임의로 연결되는 구조를 만들지 않는다"와 일치). 거절도 가능해야 한다.
- 서버는 토큰을 받으면 (1) 토큰이 유효/미사용/미만료인지, (2) 요청자와 토큰 소유 어르신이 다른 사용자인지(`elder_id != guardian_id`, 기존 CHECK 제약 유지)를 검증한 뒤에만 `guardian_links`에 pending row를 생성한다. **토큰만으로 클라이언트가 직접 `accepted` 상태를 만들 수 없다** — RLS로 차단.
- `guardian_links` 테이블은 기존과 동일하게 `status: pending | accepted | rejected | revoked` 상태를 가진다.
- QR을 사용할 수 없는 상황(카메라 미지원/권한 거부 등)을 위한 fallback 입력 방식은 이번 결정에 포함하지 않는다 — 전화번호/연결 코드를 기본 UX로 다시 도입하지 않으며, 별도 OPEN QUESTIONS로 남긴다(§5의 20번).
- `feature-spec.md`의 ADD(PROPOSED)-2("보호자 연결 2단계 인증")는 이 결정으로 **확정**(QR 토큰 발급/검증 + 어르신 수락이 인증 장치) — 추가 OTP는 최초 구현에 포함하지 않는다.
- **데이터 모델 영향(v9: 구현 완료)**: QR 토큰 발급/검증을 위해 `connection_tokens` 테이블 + `create_connection_token`/`redeem_connection_token` SECURITY DEFINER 함수를 신설했다. `guardian_links` UPDATE는 양측 모두 RLS로 행에 접근 가능하되, `pending→accepted/rejected`는 어르신만, `accepted→revoked`는 양측 모두 가능하도록 트리거로 전이를 검증한다(§4, `supabase/migrations/20260813000001~3`).

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

### 1-9. Android SMS — 전용 DataSource 격리 확정 (v11: **Phase 7 구현 완료, 실제 구현 기준으로 갱신**)

> **v11 완료 보고**: 아래 계획대로 Android는 실제 SMS inbox 자동 조회, iOS는 붙여넣기/직접 입력으로 구현 완료했다. Play Store SMS/Call Log 정책은 사용자 명시적 결정에 따라 이번 구현 판단에서 고려하지 않았다(§5 OPEN QUESTIONS 4번 DECIDED 참고). 상세는 `implementation-plan.md` Phase 7.

```
apps/senior/lib/features/message_check/
├── domain/
│   ├── entities/          # SmsMessage, SmsPermissionStatus(granted/denied/permanentlyDenied/unsupported)
│   ├── repositories/       # SmsInboxRepository(Android 자동 조회), MessageRiskRepository(분석 요청)
│   └── usecases/
├── data/
│   ├── datasources/
│   │   ├── sms_permission_datasource.dart   # permission_handler Permission.sms 래핑
│   │   └── android_sms_datasource.dart       # flutter_sms_inbox SmsQuery 래핑 — Android 전용
│   └── repositories/
│       ├── sms_inbox_repository_impl.dart              # Android 실제 구현
│       ├── unsupported_sms_inbox_repository_impl.dart  # 비Android(iOS 등) — 항상 unsupported/UnavailableFailure
│       ├── sms_inbox_repository_factory.dart            # Platform.isAndroid로 위 둘 중 선택(유일하게 platform 분기를 아는 지점)
│       └── message_risk_repository_impl.dart             # 분석 백엔드 없음 — 항상 UnavailableFailure(document_scan과 동일 패턴)
└── presentation/           # 권한 상태별 분기 UI(Android 목록/iOS 붙여넣기), AnalysisResultView 재사용(core/widgets로 승격)
```

- iOS에서는 수신 SMS 직접 읽기를 시도하지 않는다(구현 확인: iOS 코드 경로에 SMS 관련 API 호출 없음). iOS/비Android Flow: 클립보드 붙여넣기(비어있어도 오류 아님) + 직접 입력.
- **실제 채택 패키지**: `flutter_sms_inbox: ^1.0.5`(2026-08 기준 최근 갱신, 순수 inbox 조회 전용 — 발신/수신 브로드캐스트 등 불필요한 권한을 요구하는 `telephony`/`another_telephony`류 대신 최소 권한 원칙에 맞춰 선정). `telephony`는 discontinued라 채택하지 않았다. Android manifest에는 `READ_SMS`만 추가했다(`RECEIVE_SMS`/`SEND_SMS`는 요청하지 않음).
- 새 문자 자동 감지(실시간 리스너)는 이번 Phase 범위에 포함하지 않았다 — `SmsInboxRepository`는 1회성 조회(`fetchRecentMessages`)만 노출하도록 설계해, 필요해지면 별도 스트림 메서드를 추가할 수 있는 구조로 남겨두되 불필요한 백그라운드 서비스는 만들지 않았다.

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

1. **Supabase Auth로 전화번호 OTP + PIN 구조를 어떻게 구현할지 — 확정, §1-3-A 참고**
   - Supabase Phone OTP는 가입/새기기/PIN분실 등 "보안상 중요한 이벤트"에서만 쓰고, 평상시 앱 재진입은 Supabase Session은 SDK가 표준대로 유지한 채 **PIN 검증은 별도 `verify-pin` Edge Function이 서버에서 담당**하는 B안으로 확정(§1-3-A).
2. **PIN을 어떻게 안전하게 관리할지 — 확정, §1-3-A 참고**
   - PIN은 4자리 숫자 유지(경우의 수 10,000가지). 무차별 대입 방어는 자릿수가 아니라 **서버(Edge Function + DB lockout 상태) 측 lockout 정책**(5회 실패→5분 잠금, 누적 10회→30분, 이후 지수 백오프)으로 확보. 해시는 **bcrypt(v6에서 Argon2id로부터 변경 — pgcrypto DB 함수로 계산)**, 전용 `pin_credentials` 테이블에 저장하고 클라이언트/모든 DB role의 직접 접근을 RLS로 전면 차단. 클라이언트에는 PIN 원문·해시 어느 것도 저장하지 않는다.
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
   - **v14**: `document-photos` 버킷(migration `20260814000006`)으로 구현 완료. `${auth.uid()}/<file>` 경로에 대한 owner-only INSERT RLS만 두고 SELECT/UPDATE/DELETE 정책은 client 어디에도 없다 — 다운로드/삭제는 `analyze-document` Edge Function이 service role로만 수행. Signed URL 자체는 발급하지 않는다(클라이언트는 업로드만 하고, 다운로드는 서버 내부 경로로만 일어남 — "짧은 만료" 대신 "client-facing read 경로 자체가 없음"으로 더 강하게 제한).
8. **Edge Function에서 AI API Key 관리**
   - AI 분석 API Key는 Supabase Edge Function의 환경변수(Secrets)로만 저장하고, 클라이언트로 전달되는 응답에 Key나 원본 프롬프트가 노출되지 않도록 응답 스키마를 최소화해야 한다.
   - **v13**: `analyze-message`가 실제로 요구하는 secret 이름은 `ANTHROPIC_API_KEY`(Anthropic Messages API). `supabase secrets set ANTHROPIC_API_KEY=...`로 Supabase 프로젝트에 등록해야 하며, 코드/문서/로그 어디에도 실제 값을 남기지 않는다 — 이 저장소에는 값이 없다(NOT AVAILABLE, `.env.example` 대상도 아님: Edge Function secret은 Flutter `.env`가 아니라 Supabase 프로젝트 secret이라 별도 채널로 관리).
   - **v14**: `analyze-document`도 별도 키를 신설하지 않고 동일한 `ANTHROPIC_API_KEY`를 재사용한다(vision 입력만 추가, provider/시크릿 이름은 동일).
9. **원본 이미지 즉시 삭제 정책**
   - "분석 완료 후 삭제"가 실제로 지켜지는지 보장하는 메커니즘(예: 분석 성공/실패와 무관하게 일정 시간 후 자동 삭제하는 Storage 수명주기 정책)을 함께 설계해, 분석 실패 시 원본이 무기한 남는 상황을 방지해야 한다.
   - **v14**: `analyze-document`가 `finally` 블록에서 성공/실패 여부와 무관하게 업로드된 원본을 즉시 삭제하도록 구현 완료 — Storage 수명주기 정책(시간 기반 자동 삭제)에 기대지 않고, 요청 단위로 확정적으로 삭제한다. 분석 실패 시에도 orphan 업로드가 남지 않는다.
10. **계정 탈퇴 시 연결/데이터 삭제 정책**
    - 어르신 계정 탈퇴 시: 본인 데이터 삭제 + 연결된 모든 `guardian_links` 해제(보호자 쪽에는 "연결이 종료되었습니다" 안내만 남기고 어르신 개인정보는 즉시 제거) 필요.
    - 보호자 계정 탈퇴 시: 어르신 데이터에는 영향 없이 해당 `guardian_links`만 해제.
    - 기존 앱의 "회원 탈퇴 시 계정과 함께 저장된 모든 정보가 서버에서 즉시 삭제된다"는 안내 문구와 일치하도록 설계.
    - **v17 발견(Phase 11 안정화 점검)**: 실제 구현은 모든 사용자 소유 테이블(`user_roles`/`pin_credentials`/`guardian_links`/`connection_tokens`/`analysis_results`/`notifications`/`fcm_tokens`)이 `auth.users(id)`에 `on delete cascade`로 걸려 있어(마이그레이션 정적 검토로 확인, §5 신규 24번 참고) "본인 데이터 즉시 삭제"는 실제로 보장된다. 하지만 이 항목이 원래 요구한 **"보호자 쪽에는 '연결이 종료되었습니다' 안내만 남기고"** 부분은 구현되지 않았다 — cascade는 `guardian_links` 행 자체를 완전히 지워버리므로, 어르신이 탈퇴하면 보호자 쪽에는 그 연결이 있었다는 기록조차 남지 않고 조용히 목록에서 사라진다(안내 자체가 나갈 대상 레코드가 없음). 이 간극을 이번에 임의로 설계해 구현하지 않고 OPEN QUESTIONS로 남긴다 — tombstone 행 유지 여부, 안내를 어떤 채널(알림 feature? 단순 UI 문구?)로 보여줄지는 별도 제품 결정이 필요하다.

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

## 4. 확정 데이터 모델 개요 (`users`/`schedules`는 설계 참고, `pin_credentials`/`user_roles`/`guardian_links`는 v7, `analysis_results`는 v10, `notifications`/`fcm_tokens`는 v12에서 실제 migration으로 구현 완료)

> `pin_credentials`/`user_roles`/`guardian_links`/`analysis_results`/`notifications`/`fcm_tokens`는 `supabase/migrations/`에 실제 DDL이 존재한다. `users`/`schedules`는 아직 합의 수준의 개요다.

| 테이블(가칭) | 핵심 컬럼(예시) | 비고 |
|---|---|---|
| `users` | id, phone, name, age, region, easy_mode_enabled | **v5: `pin_hash`/`role` 컬럼 제거** — 각각 `pin_credentials`, `user_roles`로 분리(§1-3-A). Phase 2에는 `auth.users`(Supabase Auth 내장)만 있고 이 앱 소유의 `users` 테이블은 아직 만들지 않았다 — 프로필 필드(name/age/region 등)가 필요해지는 Phase에서 생성 |
| `pin_credentials`(v5 설계 → **v7 구현 완료**) | user_id(PK/FK), pin_hash, failed_attempts, locked_until, created_at, updated_at | §1-3-A. RLS 활성화 + `authenticated`/`anon`/`public` grant 전면 revoke로 이중 차단, `service_role`(Edge Function 경유)만 `set_pin`/`verify_pin`/`has_pin` DB 함수를 통해 접근. `pin_hash`는 bcrypt(pgcrypto `crypt()`) 결과 |
| `user_roles`(v5 설계 → **v7 구현 완료**) | id, user_id(FK), role(elder/guardian), created_at, unique(user_id, role) | §1-3-A "Role 관리". select/insert만 RLS로 허용(본인 행), update/delete 정책 없음(관리자 기능 대기) |
| `guardian_links`(**v7 구현 완료, 단 connection 기능 자체는 Phase 5**) | id, elder_id, guardian_id, status(pending/accepted/rejected/revoked), created_at, responded_at | §1-5, §1-6, §2-3. `elder_id != guardian_id` CHECK 제약 + `unique(elder_id, guardian_id)` 구현 완료. select RLS(양측 본인 행)만 구현 — insert/update(연결 요청·수락·거절·해제)는 Phase 5(connection 기능)에서 추가 |
| `connection_tokens`(**v9: 구현 완료**) | token(PK, pgcrypto 랜덤 hex), elder_id(FK), expires_at(발급 후 5분), used_at(nullable), created_at | §1-6 QR 기반 연결. `pin_credentials`와 동일하게 클라이언트 직접 접근 전면 차단(RLS + grant revoke), `service_role`만 `create_connection_token`/`redeem_connection_token` DB 함수를 통해 접근 |
| `analysis_results`(**v10: 테이블/RLS 구현 완료, v13/v14: 쓰기 경로 실제 연결, 실제 row는 이 환경에서 여전히 0건**) | id, elder_id, type(document/message), risk_level, summary, source_excerpt, reliability(높음/보통/낮음), structured_fields(JSON, 스키마 미확정) | §2 item 6. select RLS만 구현(본인 elder / accepted guardian) — insert/update/delete는 어떤 client role에도 없음(쓰기는 `analyze-message`(v13)/`analyze-document`(v14) Edge Function이 service_role로 전담). 두 Edge Function 모두 코드상 실제로 이 테이블에 insert하지만, 이 환경에는 AI provider 키/실제 Supabase 프로젝트가 없어 실제로는 여전히 빈 테이블(NOT AVAILABLE). 신뢰도/구조화 필드의 정확한 스키마는 여전히 OPEN QUESTIONS 11, 12 |
| `schedules` | id, elder_id, title, due_at, completed_at, source_analysis_id(nullable) | 분석 기록에서 분리 — `docs/product/implementation-plan.md` §1 참고 |
| `notifications`(**v12: 구현 완료, v13: read_at RPC 추가**) | id, target_user_id, type, payload(jsonb), read_at, sent_via(push/sms, default push), created_at | §1-4 채널 확장 구조 반영. select RLS만 구현(본인 `target_user_id`) — insert/update/delete는 어떤 client role에도 없음(쓰기는 `send-notification` Edge Function이 service_role로 전담). **v13**: `read_at`만 클라이언트가 안전하게 쓸 수 있도록 `mark_notification_read(p_notification_id)` SECURITY DEFINER RPC를 추가했다(전체 UPDATE 정책은 열지 않음, 본인 소유 아니면 `false`) — Guardian의 client-side `.update()`가 RLS에 막혀 조용히 0건 처리되던 버그(20260814000004)를 수정 |
| `fcm_tokens`(**v12: 구현 완료, v13: delete 정책 추가**) | id, user_id, token(unique), device_info(jsonb), updated_at | §2-5. select/insert/update RLS 구현(본인 `user_id` 행만). **v13**: 본인 `user_id` 행 한정 delete 정책을 추가해 로그아웃 시 토큰 무효화가 실제로 동작하도록 수정(이전에는 delete 정책이 없어 client `.delete()`가 조용히 0건 처리됨, 20260814000004) — 물리 토큰의 타 사용자 소유권 재할당 절차는 여전히 미구현(§5 OPEN QUESTIONS 21) |

---

## 5. OPEN QUESTIONS (아직 결정되지 않은 사항만)

> 위 §1의 Architecture 결정과 상충하지 않는 **세부 구현 방식** 수준의 질문만 남긴다. 제품/보안 방향은 모두 확정되었으므로, 아래는 각 Phase 착수 시점에 결정해도 전체 설계를 바꾸지 않는다.
>
> **v3 갱신**: 신규 요구사항(음성 비서/답변 신뢰도/보호자 고지서 통계/관리자 시스템) 관련 미결정 사항 6개를 추가하면서, 기존 항목과 번호가 겹치지 않도록 **전체를 1~14로 일괄 재정리**했다(카테고리별로 다시 1부터 시작하지 않음).

### Architecture 세부 (기존)

1. ~~Supabase Auth의 Phone OTP를 가입 시 1회성 검증에만 쓰고 별도 PIN 세션 체계를 자체 구축할지, Supabase Auth 세션 자체를 PIN 검증 게이트 뒤에 두는 방식으로 재사용할지~~ → **DECIDED**: B안(PIN 검증은 서버 Edge Function, Session은 Supabase 표준 그대로) 확정. 상세는 §1-3-A.
2. ~~보호자 연결 요청 입력 방식으로 "전화번호"와 "연결 코드" 중 하나만 채택할지, 둘 다 지원할지~~ → **DECIDED(v9)**: 둘 다 채택하지 않고 **QR 코드 기반**(서버 발급 단기 유효 토큰)으로 확정. 상세는 §1-6. QR 사용 불가 시 fallback은 20번으로 별도 이관.
3. `notifications` 테이블에서 향후 SMS 채널을 추가할 때 채널별 재시도/우선순위 정책을 어떻게 둘지(지금은 구조만 확장 가능하게 설계, 정책은 미정).
4. ~~Android SMS 접근에 사용할 실제 패키지/플러그인 선정~~ → **DECIDED(v11)**: Android는 `flutter_sms_inbox`(SMS inbox 자동 조회) 기반 실제 접근, iOS는 SMS 자동 접근 없이 복사/붙여넣기 및 직접 입력 기반 문자 확인으로 확정. 이번 결정에서는 Play Store SMS/Call Log 정책을 구현 판단의 제약으로 사용하지 않았다(사용자 명시적 결정). 상세는 §1-9.
5. `analysis_results`에 원문(문자 원문, OCR 텍스트)을 얼마나 오래/얼마나 상세히 저장할지(요약만 남길지, 원문도 일정 기간 남길지) — §2-6, §2-9와 연결된 세부 보관기간 정책.
6. ~~어르신 앱과 보호자 앱을 하나의 Flutter 앱으로 만들지, 별도 앱으로 만들지~~ → **해소(Phase 1)**: **별도 2개 Flutter 앱(`apps/senior`, `apps/guardian`) + Monorepo**로 확정. `packages/*`로 공통 코드를 공유하고, 두 앱은 서로 직접 import하지 않는다. 자세한 근거는 `architecture.md` "저장소 구조" 참고.

### UI 세부 (기존)

7. 긴급 버튼의 실제 색상값(`emergency` 토큰의 정확한 HEX) — 구조(토큰 신설 가능)는 확정, 값은 `ui-spec.md` 접근성 대비 검토 후 확정.
8. ~~쉬운 모드에서 하단 네비게이션 구성 자체(탭 개수/구성)를 바꿀지, 아이콘·크기만 바꿀지~~ → **DECIDED(v15, Phase 9)**: 탭 개수/구성은 그대로 유지하고 아이콘·라벨 스타일만 확대. `design_system`의 `AppEasyMode` 토큰 + `AppBottomNavigation(large: true)`로 구현. 상세는 `implementation-plan.md` Phase 9.

### 음성 비서 (신규, v3)

9. ~~STT/TTS 기술 및 서비스 선정~~ → **DECIDED(v16, Phase 10)**: 온디바이스(`speech_to_text`/`flutter_tts` — OS 내장 음성인식·합성 API 래퍼)로 확정. 클라우드 STT/TTS는 채택하지 않는다 — 추가 비용/API 키 관리/어르신 음성 데이터의 외부 전송이 없다. 한국어 인식 정확도는 OS 자체 엔진 수준에 의존(추후 실기기 검증 필요, NOT AVAILABLE 상태).
10. ~~음성 비서 AI 처리 방식~~ → **DECIDED(v16, Phase 10)**: (a) 클라이언트 키워드 매칭으로 확정 — `ClassifyVoiceIntentUseCase`(순수 Dart, 서버 호출 없음)가 인식된 텍스트를 소수의 고정 명령(문서 촬영/문자 확인/긴급 도움)에 매칭한다. §1-7(위험 문자 판단)의 "AI 처리는 서버 경유" 원칙은 문자/문서 내용의 실제 위험·의미 판단에 적용되는 것이고, 음성 비서의 "몇 개 안 되는 고정 명령을 온담 기능에 연결"하는 것은 그 판단에 해당하지 않는다고 판단해 서버 AI를 도입하지 않았다. 지원 명령이 늘거나 자유 발화 질의응답이 필요해지면 그때 서버 AI 의도분류 재검토(신규 OPEN QUESTIONS로 남김, §5 23번).

### 답변 신뢰도 (신규, v3)

11. **신뢰도 산정 기준과 사용자 표현 방식**: 어떤 근거로 "높음/보통/낮음"을 나눌지(AI 모델의 원시 confidence score를 구간화할지, 별도 규칙을 둘지), 그리고 이를 "이 답변은 비교적 확실해요" 같은 문구로 매핑하는 정확한 규칙(UX Writing)을 어떻게 정의할지 — `ui-spec.md`에 별도 UX 규칙으로 정의하기로 했으나 구체적 기준표는 아직 없음.

### 보호자 고지서 통계 (신규, v3)

12. **고지서 통계의 최종 데이터 항목**: 월별 고지서/금액 변화/주요 항목/기간 대비 변화/이상 변화/분석 건수 중 최초 구현에 포함할 항목과 우선순위 — "별도 Feature Spec에서 결정"하기로 확정, 아직 그 Feature Spec은 작성되지 않음.

### 관리자 시스템 (신규, v3, PROPOSED 자체가 미결정)

13. 관리자 기능을 별도 관리자 앱(Flutter 등)으로 제공할지, 웹 관리자 페이지로 제공할지 결정 필요.
14. 관리자 시스템을 초기 MVP 범위에 포함할지, 완전히 제외하고 이후 로드맵으로 미룰지 결정 필요.

### Authentication 세부 (v5 신규, v6에서 15~17 해소)

15. ~~Senior/Guardian 앱에 동일 전화번호로 양쪽 role(elder+guardian)을 동시에 가질 수 있게 허용할지~~ → **DECIDED(v6)**: B안(동시 허용) 확정. 상세는 §1-3-A "Role 관리".
16. ~~PIN 해시에 Argon2id를 Supabase Edge Function(Deno 런타임) 환경에서 어떤 라이브러리/방식으로 구현할지~~ → **DECIDED(v6)**: Argon2id 대신 **bcrypt(pgcrypto, DB 함수)**로 변경 확정 — 기술 검증 근거는 §1-3-A "PIN 해시 알고리즘 기술 검증".
17. ~~앱 재진입(cold start/idle timeout) 시 PIN 재확인을 요구하는 구체적 idle timeout 값~~ → **DECIDED(v6)**: Senior 15분 / Guardian 5분. 상세는 §1-3-A "앱 재진입 idle timeout".
18. **Guardian 앱에 생체인증(지문/FaceID)을 PIN의 대체/보완 수단으로 추가할지 — OPEN(유지)**: Phase 2 범위에는 포함하지 않기로 했으나(§1-3-A "Guardian 생체인증"), 채택 여부 자체는 아직 결정되지 않았다.
19. **(v6 신규) Senior/Guardian idle timeout 값을 사용자가 직접 조정할 수 있게 설정 UI를 제공할지** — 지금은 15분/5분 고정값으로 시작(§1-3-A).

### 연결(Connection) 세부 (v9 신규)

20. **QR 코드를 사용할 수 없는 상황(카메라 미지원/권한 거부 등)의 fallback 입력 방식** — §1-6에서 QR을 기본 방식으로 확정하면서, 전화번호/연결 코드를 기본 UX로 다시 도입하지 않기로 했다. fallback 자체의 필요 여부와 방식은 별도 결정으로 남긴다.

### 알림(Notification) Backend 세부 (v12 신규)

21. ~~`fcm_tokens` 토큰 무효화 절차~~ → **DECIDED(v13)**: 본인 행 한정 delete 정책을 추가해 로그아웃 시 실제로 토큰이 삭제되도록 구현했다(§4 `fcm_tokens` 참고). **단, 소유권 재할당은 여전히 미구현으로 OPEN 유지**: 같은 물리 토큰이 다른 사용자 소유로 넘어가는 경우(기기를 다른 사람에게 넘김 등) — 그 토큰 문자열이 이미 다른 `user_id` 행에 `unique` 제약으로 걸려 있으면 새 소유자의 insert/update가 그냥 실패한다. 실제 발생 빈도가 낮고 우회(로그아웃 시 delete가 정상 동작하면 대부분 자연히 해소)도 있어 우선순위 낮음으로 남긴다.

### AI 분석 Backend 세부 (v13 신규, v14: document_scan으로 확장)

22. **AI provider 실제 자격증명/모델 운영 정책** — `analyze-message`는 Anthropic Messages API(`claude-haiku-4-5-20251001`, `ANTHROPIC_API_KEY` secret)로 구현했다(§1-7). **v14**: `analyze-document`도 동일 모델/시크릿을 vision 입력으로 재사용한다. 이 환경에는 실제 키가 없어 호출 자체는 검증하지 못했다(NOT AVAILABLE). 실제 운영 시 (a) 이 모델/provider를 그대로 쓸지 재검토, (b) 비용/rate limit 정책, (c) 오분류(문자: false negative로 위험 문자를 safe로 판정 / 문서: 고지서 금액·기한을 잘못 읽음) 발생 시 사용자/보호자에게 미치는 영향에 대한 완화책은 실제 운영 데이터 없이는 결정할 수 없어 OPEN으로 남긴다.

### 음성 비서(Voice Assistant) 세부 (v16 신규)

23. **지원 명령이 늘어나거나 자유 발화 질의응답이 필요해질 때의 서버 AI 의도분류 도입 여부** — Phase 10은 클라이언트 키워드 매칭(문서 촬영/문자 확인/긴급 도움 3개 고정 명령)만 지원한다(§5-2 OPEN QUESTIONS 10 DECIDED). "경로당 찾아줘"처럼 아직 없는 기능(`welfare_center`)에 대한 음성 명령이나, 고정 문구가 아닌 자연스러운 질문("보이스피싱 문자인지 확인해줘" 등)까지 지원하려면 그때 서버 AI 의도분류(§1-7과 동일한 Edge Function 패턴) 재검토가 필요하다.

### 계정 탈퇴 세부 (v17 신규, Phase 11 안정화 점검에서 발견)

24. **어르신 탈퇴 시 보호자에게 "연결이 종료되었습니다" 안내를 남기는 방식** — §2 item 10이 원래 요구한 사항이지만, 실제 구현(`guardian_links.elder_id on delete cascade`)은 탈퇴 즉시 연결 행 자체를 완전히 삭제해 보호자 쪽에 안내를 남길 대상 레코드가 없다. tombstone 행(예: 상태만 `revoked`로 바꾸고 어르신 개인정보 컬럼은 없는 구조)을 별도로 유지할지, 아니면 "안내 없이 조용히 사라짐"을 최종 사양으로 받아들일지 결정 필요. 결정되면 `notification`/`connection` 중 어느 feature가 이 안내를 책임질지도 함께 정해야 한다.

> 위 목록에 없는 항목(Backend, DB, 인증 큰 흐름 — **OTP+PIN+Session 결합 방식, PIN 해시 알고리즘, Role 동시허용 정책, idle timeout 값 포함**, 알림 채널, 관계 카디널리티, 연결 인증 방식(QR 기반 확정 포함), 위험판단 주체, 원본 보관, SMS 격리, Push, 로컬 저장소 분리, 쉬운모드 범위/Main 격상, Empty State/Loading 정책, 미리보기 제거, 신규 기능 6개의 제품 방향, 어르신/보호자 앱 분리 구조, **음성 비서 STT/TTS 및 의도분류 방식**)은 **모두 확정**되었다. 위 24개 중 1·2·4·6·8·9·10·15·16·17·21번이 해소되어(21번은 토큰 무효화만 해소, 소유권 재할당은 여전히 OPEN), 실질적으로 남은 것은 13개(3·5·7·11·12·13·14·18·19·20·22·23·24번)다. 나머지는 순수 **기술/세부 구현 방식** 미결정 사항이다.

---

## 6. Phase 4 구현 완료 요약 (v8, v14: AI 분석 백엔드 실제 연결)

> **v14 추가 구현**: v8에서 골격만 만들고 "항상 `UnavailableFailure`"로 남겨뒀던 실제 AI 분석 백엔드를 연결했다. `analyze-document` Edge Function(§1-7/§1-8, `analyze-message`와 동일 구조 — tool-forced 구조화 출력, Anthropic Messages API, `document_classifier.ts`로 검증/파싱 로직을 분리해 Deno.serve 부작용 없이 유닛 테스트 가능하게 구성) + `document-photos` private Storage 버킷(migration `20260814000006`)을 신규 작성했다. `AnalysisRemoteDataSource`가 client JWT로 사진을 업로드하고 저장 경로만 Edge Function에 전달하며, Edge Function은 service role로 다운로드/분석 후 `finally`에서 원본을 즉시 삭제한다. `AnalysisRepositoryImpl`은 `analyze-message`와 동일한 reason-code → `Failure` 매핑을 따른다. 아래 "Camera/Analysis 골격 구현 요약"의 "백엔드 없음 처리" 서술(`AnalysisRepositoryImpl.analyzeDocument()`가 항상 `Err(UnavailableFailure())`)은 이제 실제 백엔드 호출로 대체됐다 — 상세는 `implementation-plan.md` Phase 4 v14 항목.

### AnalysisResult 도메인 모델 재검토

Phase 4 착수 전, `packages/models/lib/src/analysis_result.dart`가 카메라/분석 화면 요구사항을 충분히 표현하는지 먼저 검토했다(임의로 필드부터 추가하지 않는다는 원칙에 따라).

**결론: 신규 필드 추가 없이 현재 모델로 충분하다.**

- `reliability`(`ReliabilityLevel`) — `AppConfidenceIndicator`가 그대로 소비, 충분.
- `riskLevel`(nullable `RiskLevel`) — `AppRiskBadge`가 그대로 소비, 문서 분석에는 없을 수 있어(nullable) 충분.
- `structuredFields`(`Map<String, Object?>?`, 의도적으로 열린 형태) — 고지서 금액/기한/항목을 스키마 미확정 상태로도 제네릭하게 렌더링 가능(`AnalysisResultView`가 key-value 순회만 함, 특정 키를 가정하지 않음). **정확한 항목 스키마는 여전히 OPEN QUESTIONS 12** — 이번에도 임의로 확정하지 않았다.
- `sourceExcerpt`/`summary` — 결과 화면의 원문/요약 표시에 충분.
- 검토했으나 추가하지 않은 필드: "고지서 종류(billType/documentCategory)" 같은 분류 필드 — 통계 항목이 아직 미정(OPEN QUESTIONS 12)인 상태에서 분류 스키마부터 정하면 그 결정을 앞지르게 된다. 필요해지면 OPEN QUESTIONS 12가 해소되는 시점에 함께 추가한다.
- **원본 이미지 참조 필드는 의도적으로 없다** — §1-8(분석 완료 후 원본 즉시 삭제) 정책상 분석 후에는 참조할 원본이 남지 않아야 하므로, `AnalysisResult`가 영속적인 이미지 URL을 갖는 것 자체가 정책과 모순된다.

### Camera/Analysis 골격 구현 요약

`document_scan` feature(Senior 전용)에 카메라 권한(`CameraRepository`)·분석 요청(`AnalysisRepository`) 도메인/데이터/프레젠테이션 계층을 구현했다. 상세 구조와 "왜 `CameraController`가 Repository가 아니라 `StatefulWidget`에 있는지"는 `architecture.md` "Camera Architecture" 참고.

- **백엔드 없음 처리 (v8 당시, v14에서 대체됨)**: v8 시점에는 `AnalysisRepositoryImpl.analyzeDocument()`가 항상 `Err(UnavailableFailure())`를 반환했다 — Storage 업로드도, Edge Function 호출도 시도하지 않았다. **v14**: `analyze-document` Edge Function이 실제로 연결되면서 이 무조건 반환은 사라졌다 — `UnavailableFailure`는 이제 "AI provider 시크릿 미설정" 같은 실제 조건에서만 나오는 정직한 결과 중 하나다(§6 상단 v14 노트 참고). 결과 화면은 여전히 이를 일반 오류(재시도 유도)와 구분해서 보여준다.
- **신규 패키지**: `camera`(Android/iOS 카메라 프리뷰+촬영), `permission_handler`(카메라 권한, Android `compileSdk 37` 요구 버전을 피해 `^12.0.0`으로 고정 — `compileSdk 36` 환경과 호환). 둘 다 `apps/senior`에만 추가, Guardian에는 추가하지 않았다.
- **`analysis_results` 테이블 (v8 당시, v10에서 생성됨)**: v8 시점에는 아직 DB에 존재하지 않았다. **v10**에서 실제 테이블/RLS로 생성됐고(§4), **v14**에서 `analyze-document`가 실제 insert 경로로 연결됐다.
