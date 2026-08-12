---
name: feature-development
description: 온담앱에 새로운 기능(feature)을 추가할 때 따르는 workflow. 요구사항 분석부터 검증까지 순서를 강제해 중복 구현과 아키텍처 위반을 막는다.
---

# feature-development

새 기능 요청을 받으면 아래 순서를 따른다. 순서를 건너뛰지 않는다 — 특히 "관련 코드 탐색"과 "현재 구조 확인"을 생략하고 바로 구현으로 넘어가지 않는다.

## Workflow

```
1. 요구사항 분석
2. 관련 코드 탐색
3. 현재 구조 확인
4. 데이터 흐름 설계
5. Domain 설계
6. Repository 설계
7. DataSource 설계
8. Provider 설계
9. UI 설계
10. 구현
11. 테스트
12. format
13. analyze
14. 검증
```

### 1. 요구사항 분석

무엇을 만드는지, 범위가 어디까지인지 명확히 한다. 불명확하면 구현 전에 사용자에게 확인한다. 요청받지 않은 화면/기능을 임의로 추가하지 않는다.

### 2. 관련 코드 탐색

`lib/features/`에 이미 비슷한 기능이 있는지 먼저 확인한다. `lib/core/`에 재사용 가능한 위젯/유틸이 있는지 확인한다. 중복 구현하지 않는다.

### 3. 현재 구조 확인

`architecture.md`의 feature 구조를 다시 확인한다. 이번 기능이 data/domain/presentation 3계층을 모두 필요로 하는지, 아니면 더 단순한 구조로 충분한지 판단한다.

### 4. 데이터 흐름 설계

`UI → Provider → UseCase → Repository → DataSource → API/DB` 흐름에서 이번 기능이 어느 지점부터 시작하는지(신규 API 필요 여부, 로컬 상태만으로 충분한지) 결정한다.

### 5~9. 계층별 설계

domain(entity/usecase) → repository 인터페이스 → datasource → provider → UI 순으로 설계한다. domain은 Flutter/외부 패키지에 의존하지 않는다 (`architecture.md` 참고). API 관련 설계는 `api.md`, 상태관리는 `riverpod.md`, UI 토큰은 `ui-design.md`를 따른다.

### 10. 구현

설계한 순서(domain → data → presentation)대로 구현한다. 위젯에서 API를 직접 호출하지 않는다.

### 11. 테스트

`testing.md` 기준에 따라 최소한 domain(UseCase) 테스트를 작성한다.

### 12~14. format / analyze / 검증

```
dart format .
flutter analyze
flutter test
```

실패하면 완료로 보고하지 않는다. Flutter SDK가 설치되어 있지 않은 환경이라면 "NOT AVAILABLE"로 명시하고 사용자에게 알린다.
