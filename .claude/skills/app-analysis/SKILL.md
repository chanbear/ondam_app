---
name: app-analysis
description: 기존 온담앱 자료(테스트 링크/화면 캡처/녹화/APK/기존 소스/문서)를 분석해 KEEP/MODIFY/REMOVE/ADD로 분류하고 docs/product·ui에 문서화할 때 사용. 이 단계에서는 구현하지 않는다.
---

# app-analysis

기존 온담앱의 테스트 링크, 화면 캡처/녹화, APK, 기존 소스코드, 문서, API 문서, 요구사항 등을 제공받으면 이 workflow를 따른다. **분석 단계에서는 코드를 작성하지 않는다.**

## Workflow

```
1. 자료 확인
2. 화면 분석
3. 기능 분석
4. 사용자 Flow 분석
5. 현재 문제점 분석
6. KEEP / MODIFY / REMOVE / ADD 분류
7. 기능 명세 작성 (feature-spec.md)
8. UI 명세 작성 (ui-spec.md)
9. Architecture 영향 분석
```

### 1. 자료 확인

무엇이 제공됐는지 먼저 확인한다 (링크/캡처/영상/APK/소스/문서). 자료가 부족해 확인할 수 없는 부분은 추측하지 않고 "확인 필요"로 표시한다. 단순히 화면에 보이는 것만으로 내부 동작(서버 로직, 데이터 검증 규칙 등)을 확정하지 않는다.

### 2. 화면 분석

화면 목록, 화면별 목적, 화면 이동(Navigation/Modal/Bottom Sheet/Dialog/Tab), 상태별 화면(로딩/에러/빈 상태)을 정리한다.

### 3. 기능 분석

각 기능마다 다음을 기록한다:

```
기능명
현재 동작
문제점
유지/수정/삭제 여부 (잠정)
새로운 요구사항 (있다면)
```

### 4. 사용자 Flow 분석

실제 화면 이동 순서를 흐름도로 정리한다 (예: Splash → 로그인 → 홈 → 상세 → 행동 → 결과).

### 5. 현재 문제점 분석

UX 문제, 성능 문제, 구조적 문제(코드가 보이는 경우), 일관성 없는 UI 등을 기록한다. 이 프로젝트로 가져오면 안 되는 기술 부채도 여기서 표시한다.

### 6. KEEP / MODIFY / REMOVE / ADD 분류

기능 단위로 분류한다.

- **KEEP**: 그대로 또는 거의 동일하게 재구현
- **MODIFY**: 필요하지만 UX/오류/구조/기능 부족 등의 이유로 수정
- **REMOVE**: 더 이상 필요 없거나 새 방향과 맞지 않음
- **ADD**: 기존에 없지만 새로 필요

### 7~8. 문서화

분석 결과를 아래 파일에 기록한다. 사용자가 확인하기 전에 이 문서들을 근거로 대규모 구현을 시작하지 않는다.

```
docs/product/current-app-analysis.md   # 화면/기능/문제점 분석 원본
docs/product/feature-spec.md            # KEEP/MODIFY/REMOVE/ADD 반영한 최종 기능 명세
docs/product/user-flow.md               # 사용자 Flow
docs/ui/ui-spec.md                      # UI 방향 (기존 UI 참고, 토큰 체계로 매핑)
```

기존 UI를 그대로 복제할 필요는 없다 — `ui-design.md`의 토큰 체계로 재해석한다.

### 9. Architecture 영향 분석

새로 파악된 기능이 `lib/features/` 어디에 들어가야 하는지, 기존 core 코드로 충분한지, 새 core 모듈(예: storage)이 필요한지 `docs/architecture/architecture.md`에 기록한다.

## 완료 조건

문서화가 끝나면 구현을 바로 시작하지 않고 사용자 확인을 기다린다. 확인 후 `feature-development` skill로 넘어간다.
