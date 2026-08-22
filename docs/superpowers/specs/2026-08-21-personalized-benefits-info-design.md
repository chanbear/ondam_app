# 나이/성별/지역 기반 맞춤 혜택 정보 — 설계 문서

## 배경

`apps/senior`의 하단 탭 4개 중 "정보" 탭(`lib/features/home/presentation/pages/info_tab_page.dart`)은 현재 완전히 빈 상태다(`AppEmptyState`만 표시). `lib/features/info/`는 폴더(`.gitkeep`)만 존재하고 domain/data 계층이 없다.

기존 온담앱(레거시)은 이 탭에서 프로필의 나이만 기준으로 "OO님을 위한 정보" 카드 3개(기초연금 신청 안내/무료 건강검진/보이스피싱 예방)를 **하드코딩**해서 보여줬다. `docs/product/current-app-analysis.md` §2-6은 이를 KEEP(나이 기반 개인화 자체는 좋은 방향)으로 분류하면서도, "콘텐츠가 3개로 고정되어 있어 개인화 폭이 제한적"이라는 문제점을 명시했다. `docs/product/feature-spec.md`의 KEEP-7("나이 기반 맞춤 정보 카드")과 `docs/ui/ui-screen-spec.md`의 "정보(info)" 화면 스펙도 같은 기능을 이미 요구사항으로 확정해뒀다.

이번 요청은 이 문서화된 요구사항을 실제로 구현하는 것이며, 레거시의 핵심 문제(하드코딩이라 사람마다 내용이 안 바뀜)를 **공공데이터포털 Open API 실시간 조회**로 해소한다 — 나이·성별·거주 지역 조합에 따라 결과가 달라진다.

## 범위

- `apps/senior` 전용. `apps/guardian`은 이번 범위에 포함하지 않는다.
- 나이/성별은 어르신 본인이 senior 앱의 "내 정보"(`features/profile`) 화면에서 입력한다(지역 입력과 동일한 화면/패턴).
- MVP는 목록 + 상세 페이지까지 포함한다(신청 방법/문의처/외부 링크 등 상세 정보 표시).
- 데이터 소스는 공공데이터포털(data.go.kr) "한국사회보장정보원_지자체복지서비스" + "한국사회보장정보원_중앙부처복지서비스" Open API로 진행하고, 실제 서비스키 발급 후 라이브 검증한다(문서만으로 성별 필터 지원 여부를 확정할 수 없었음 — 아래 "리스크" 참고).

## 데이터 모델

### Migration: `users` 테이블에 컬럼 추가

```sql
alter table public.users
  add column age smallint,
  add column gender text check (gender in ('male', 'female'));
```

- `region_*` 컬럼과 동일하게 nullable — 아직 입력하지 않은 사용자도 존재한다.
- 기존 RLS 정책(`users_select_own`/`users_insert_own`/`users_update_own`)이 이미 행 전체를 `id = auth.uid()` 기준으로 다루므로 정책 추가 불필요.
- `technical-decisions.md` §4의 `users` 스케치(`id, phone, name, age, region, easy_mode_enabled`)에는 `gender`가 없었다 — 이번 기능 때문에 신규로 필요해진 필드로, 문서에 그렇게 반영한다(스펙 문서 승인 후 `technical-decisions.md`에 v19 항목 추가).

## `core/demographics/` (신규)

나이/성별은 `profile`(쓰기)과 `info`(읽기, API 검색 조건) 두 feature가 공유하므로, `core/location`(region)과 동일한 이유로 core에 둔다.

```
core/demographics/
├── domain/
│   ├── entities/demographics.dart       # age: int?, gender: Gender?  (enum Gender { male, female })
│   ├── repositories/demographics_repository.dart
│   └── usecases/
│       ├── get_my_demographics_usecase.dart
│       └── save_demographics_usecase.dart
├── data/
│   ├── datasources/demographics_remote_datasource.dart   # region_remote_datasource.dart와 동일 패턴:
│   │                                                       # Supabase `users` 테이블 직접 upsert/select, RLS로 접근 제어
│   ├── models/demographics_model.dart
│   └── repositories/demographics_repository_impl.dart
└── presentation/providers/
    ├── demographics_di_providers.dart
    └── demographics_provider.dart        # AsyncNotifierProvider<DemographicsNotifier, Demographics?>, region_provider.dart와 동일 구조(저장 후 재조회)
```

기존 `RegionRemoteDataSource`/`region_provider.dart`는 수정하지 않는다 — 독립된 새 파일로 추가(단일 책임 유지, region 코드에 회귀 위험 없음).

## `features/profile` 변경

- `profile_page.dart`: `_save()`가 스낵바만 띄우던 것을 `demographicsProvider.notifier.save(...)` 호출로 교체. 나이는 기존 `_ageController` 값을 파싱해서 사용.
- 성별 선택 UI 신규 추가 — 2지선다(남/여), `AppButton` 계열 세그먼트 컨트롤. 새 색상/spacing은 만들지 않고 기존 토큰만 사용.
- 저장 실패 시 `AppError` 패턴이 아니라 기존 스낵바 UX를 유지하되 실제 에러 메시지(`Failure.message`)를 보여준다.

## Edge Functions (신규)

`welfare_center`(특히 PHASE 35의 라이브 검증 교훈)와 동일한 구조를 따른다: `index.ts`(I/O)와 순수 로직 파일 분리, `_shared/cors.ts`·`_shared/http.ts`·`_shared/auth.ts` 재사용, `DATA_GO_KR_SERVICE_KEY` secret 재사용(단, 이 두 데이터셋은 공공데이터포털에서 **개별 활용신청**이 필요할 수 있어 사용자 확인 필요 — 아래 리스크 참고).

```
supabase/functions/
├── search-benefit-services/          # 목록조회 — 중앙부처+지자체 복지서비스 API 조합
│   ├── index.ts
│   ├── benefit_service_client.ts
│   └── benefit_service_client.test.ts
└── get-benefit-service-detail/       # 상세조회 — servId 파라미터
    ├── index.ts
    ├── benefit_service_detail_client.ts
    └── benefit_service_detail_client.test.ts
```

- 요청: `{ age: number, gender: 'male' | 'female', region: { sido: string, sigungu: string } }`
- 응답: `{ ok: true, results: BenefitServiceDto[] }` 또는 `{ ok: false, reason: string }` — `data_source_not_configured`/`upstream_error`/`upstream_timeout`/`upstream_invalid_response` 등 `search-welfare-centers`와 동일한 reason 체계.
- 성별 필터는 API가 실제로 지원하는지 확정되기 전까지는 **서버 응답을 그대로 통과**시키고 클라이언트 요청에는 포함하되 무시될 수 있음을 주석에 남긴다(라이브 검증 후 확정).
- `search-welfare-centers`처럼 지역 필터가 서버 측에서 불완전할 가능성을 열어두고, 필요하면 클라이언트(Edge Function) 쪽에서 주소/지역 문자열로 추가 필터링한다.

## `features/info/` (신규 domain/data/presentation)

`welfare_center`와 동일 계층 구조로 채운다.

```
features/info/
├── domain/
│   ├── entities/benefit_service.dart          # id(servId), title, summary, supportTarget, applyMethod?, contact?, externalUrl?
│   ├── repositories/benefit_service_repository.dart
│   └── usecases/
│       ├── search_benefit_services_usecase.dart
│       └── get_benefit_service_detail_usecase.dart
├── data/
│   ├── datasources/benefit_service_remote_datasource.dart   # functions.invoke('search-benefit-services'/'get-benefit-service-detail')
│   ├── models/benefit_service_model.dart
│   └── repositories/benefit_service_repository_impl.dart     # NetworkException/FunctionException → Failure
└── presentation/
    ├── providers/
    │   ├── benefit_service_di_providers.dart
    │   └── benefit_service_notifier.dart      # welfare_center_notifier.dart와 동일 패턴
    ├── pages/
    │   ├── benefit_service_detail_page.dart
    │   └── (info_tab_page.dart는 home/ 아래 기존 위치 유지, 내용만 교체)
    └── widgets/ (필요 시 카드 위젯 분리)
```

- `info_tab_page.dart`: 빈 상태를 걷어내고 `regionProvider` + `demographicsProvider`를 함께 구독. 나이/성별/지역 중 하나라도 비어 있으면 `welfare_center_list_page.dart`의 "내 지역 입력하기" CTA와 동일한 패턴으로 "내 정보 입력하기" 안내(→ `ProfilePage`로 이동)를 보여준다. 모두 채워졌으면 자동으로 검색해 목록을 보여준다.
- 목록 카드: `welfare_center`의 `_SeniorCenterCard`와 동일한 `AppCard` 기반 레이아웃(제목/요약, 탭하면 상세로 이동).
- 상세 페이지: 지원대상/신청방법/문의처/외부 링크 표시, `url_launcher`로 전화/웹 링크 연결(기존 `welfare_center_list_page.dart`의 `_callPhone` 패턴 재사용).

## 테스트

- `benefit_service_client.test.ts` / `benefit_service_detail_client.test.ts`: 요청 바디 검증, 응답 파싱(성공/NODATA/오류 코드) — `welfare_center_client.test.ts`와 동일 스타일의 Deno 테스트.
- `DemographicsRepository` 유닛 테스트: datasource 예외 → `Failure` 매핑.
- `SearchBenefitServicesUseCase`/`GetBenefitServiceDetailUseCase` 유닛 테스트: 성공/실패/빈 결과 분기.
- `info_tab_page` 위젯 테스트: 프로필 미입력(CTA) / 로딩 / 목록 있음 / 빈 결과 / 에러 상태.
- `profile_page` 위젯 테스트: 성별 선택 UI 상호작용, 저장 성공/실패 분기.

## 리스크 / 확정되지 않은 사항 (구현 중 라이브 검증 필요 — `welfare_center` PHASE 35와 동일한 패턴)

1. **성별 필터 지원 여부**: 공공데이터포털 Swagger 문서를 로그인 없이 확인하지 못해, 두 API가 성별 조건을 실제로 지원하는지 문서만으로 확정하지 못했다. 서비스키 발급 후 실API 응답으로 검증한다.
2. **활용신청 필요 여부**: "지자체복지서비스"/"중앙부처복지서비스" 데이터셋이 기존 `DATA_GO_KR_SERVICE_KEY`로 바로 호출 가능한지, 별도 활용신청(승인 대기)이 필요한지 확인이 필요하다.
3. **상세조회 파라미터명**: 목록조회 응답의 어떤 필드가 상세조회 API의 키(`servId` 등 실제 필드명)로 쓰이는지는 실제 응답을 봐야 확정된다.
4. 위 세 가지는 설계를 막지 않는다 — 방어적으로 구현하고(문서 기반 최선 추정), 실제 서비스키로 검증되는 즉시 `welfare_center_client.ts`처럼 주석으로 실제 스펙과의 차이를 기록하고 코드를 보정한다.

## 범위 밖

- `apps/guardian` 연동(보호자가 대신 입력/열람).
- 소득/재산 등 추가 조건 기반 정교한 필터링(선정기준 자동 판정) — 이번 phase는 나이/성별/지역만 사용한다.
- 알림(새 혜택 발생 시 푸시) — 별도 요구사항 없음.
