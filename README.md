# ondam

온담은 **온담 어르신 앱**과 **온담 보호자 앱**, 두 개의 독립적인 Flutter 앱으로 구성되며, 하나의 Monorepo(Dart/Flutter pub workspace)에서 공통 패키지를 공유한다.

## 구조

```text
ondam/
├── apps/
│   ├── senior/       # 온담 어르신 앱 (com.ondam.senior)
│   └── guardian/     # 온담 보호자 앱 (com.ondam.guardian)
│
├── packages/
│   ├── core/            # Failure 등 프레임워크 비의존 공용 타입
│   ├── design_system/   # AppColors/AppTextStyles/AppSpacing/AppRadius/AppTheme + 공용 위젯
│   ├── models/          # 두 앱이 같은 모양을 써야 하는 공유 모델(AnalysisResult, GuardianLink 등)
│   ├── network/          # 공용 DioClient/NetworkException/ErrorInterceptor
│   ├── storage/          # Secure/Local Storage 분리 기반
│   └── shared/           # (현재 비어있음) 실제 공통 유틸리티가 필요해질 때 채운다
│
└── docs/                 # 제품/아키텍처/UI 문서
```

두 앱은 서로 직접 import하지 않는다. 각 앱은 `packages/*`만 의존하고, `packages/*`는 어떤 `apps/*`에도 의존하지 않는다.

```text
Senior App  → packages/* → Backend
Guardian App → packages/* → Backend
```

## 개발 환경

- Flutter 3.44.9 / Dart 3.12.2
- 상태관리: Riverpod (코드젠 없이 수동 Provider)
- 라우팅: go_router (앱별 독립 라우터, `apps/<app>/lib/app/router/`)
- 네트워크: Dio (`packages/network`의 `DioClient` — baseUrl은 각 앱이 자신의 `.env`에서 주입)
- Monorepo: Dart/Flutter **native pub workspace**(`pubspec.yaml`의 `workspace:` 필드) — melos는 사용하지 않는다. 이유는 `docs/architecture/architecture.md` 참고.

## 시작하기

```bash
# 루트에서 전체 workspace 의존성 한 번에 resolve
flutter pub get

# 어르신 앱 실행/검증
cd apps/senior
cp .env.example .env   # 값은 비워둔 채로 시작
flutter run

# 보호자 앱 실행/검증
cd apps/guardian
cp .env.example .env
flutter run
```

## 문서

`docs/product/`, `docs/architecture/`, `docs/ui/`에 제품 분석·아키텍처 결정·UI 명세가 정리되어 있다. 특히 `docs/architecture/technical-decisions.md`의 OPEN QUESTIONS는 아직 해결되지 않은 세부 구현 사항이다.
