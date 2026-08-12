---
name: ui-redesign
description: 기존 온담앱 기능은 유지한 채 UI만 변경할 때 따르는 workflow. data/domain/API/인증 로직을 UI 변경 때문에 임의로 건드리지 않도록 범위를 강제한다.
---

# ui-redesign

"UI를 좀 더 깔끔하게 바꿔줘" 같은 요청을 받으면 바로 코드를 수정하지 않는다. 아래 순서를 따른다.

## 핵심 규칙

**기존 기능을 유지한다.** 다음 영역은 UI 변경을 이유로 임의로 수정하지 않는다:

```
lib/*/data/
lib/*/domain/
API
Repository
DataSource
Authentication
Database
핵심 Provider (비즈니스 로직을 담은 Notifier 등)
```

정말 필요한 경우에만: (1) 변경 이유를 설명 → (2) 영향 범위를 확인 → (3) 최소한으로 변경 → (4) 회귀 테스트.

## Workflow

```
1. 현재 화면/기능 분석
2. 현재 기능과 데이터 흐름 분석
3. UI와 business logic 경계 확인
4. 변경 가능한 UI 영역 확인
5. 변경 금지 영역 확인
6. 새로운 UI 방향 결정
7. Design System 수정 (필요 시)
8. Widget 수정
9. 기능 코드 변경 여부 확인
10. Android 검증
11. iOS 검증 (가능한 환경에서만)
12. 회귀 테스트
```

### 1~3. 분석

변경 대상 화면의 현재 Widget 트리, 연결된 Provider, 그 Provider가 호출하는 UseCase/Repository를 먼저 파악한다. 어디까지가 순수 UI이고 어디부터 business logic인지 경계선을 명확히 그은 뒤에 작업을 시작한다.

### 4~6. 범위와 방향 결정

무엇을 바꿀 수 있고 무엇을 바꾸면 안 되는지 결정한 다음, 디자인 방향(색상/레이아웃/컴포넌트)을 정한다. 필요하면 `frontend-design` 스킬/플러그인을 시각적 방향 제안에 활용하되, 이 프로젝트의 아키텍처(`architecture.md`)나 디자인 토큰 체계(`ui-design.md`)를 무시하는 제안은 따르지 않는다.

### 7~8. Design System / Widget 수정

색상·spacing·radius·typography 변경은 `lib/app/theme/`의 토큰 파일을 수정한다 (`ui-design.md` 참고). 위젯 코드에 하드코딩하지 않는다. 여러 화면에서 쓰는 위젯을 바꾸면 다른 화면에 미치는 영향을 함께 확인한다.

### 9. 기능 코드 변경 여부 확인

작업이 끝나면 diff를 다시 훑어 다음을 확인한다:

```
UI 외의 코드가 변경되었는가?
Provider가 불필요하게 변경되었는가?
API 코드가 변경되었는가?
Repository가 변경되었는가?
기존 navigation이 깨졌는가?
기존 기능이 사라졌는가?
```

발견되면 이유를 확인하고, 불필요한 변경은 되돌린다.

### 10~12. 검증

Android에서 먼저 확인하고, macOS/Xcode 환경이 있으면 iOS도 확인한다 (Windows에서는 iOS 빌드 자체가 불가 — 코드 작성까지만). 기존 사용자 흐름이 그대로 동작하는지 회귀 확인한다.
