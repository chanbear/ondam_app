---
name: edge-function-development
description: supabase/functions/ 아래 Edge Function을 새로 추가하거나 수정할 때 따르는 workflow. index.ts(I/O)와 순수 로직 파일을 분리하고, _shared/ 재사용, 응답 reason code, 테스트 컨벤션을 강제한다.
---

# edge-function-development

`supabase/functions/analyze-message`, `analyze-document` 등에서 이미 반복되고 있는 구조를 따른다. Flutter 쪽 기능은 `feature-development` skill을 따르지만, Edge Function은 별도 계층(Deno/TypeScript, Supabase 프로젝트)이므로 이 skill을 사용한다.

## 기존 구조 (반드시 먼저 확인)

```
supabase/functions/
├── _shared/                     # 두 개 이상 함수가 공유하는 코드만
│   ├── cors.ts
│   ├── http.ts                  # json() 응답 헬퍼
│   ├── auth.ts                  # verifyCaller() — JWT 검증 + serviceClient
│   └── risk_floor.ts            # 예: 여러 함수가 재사용하는 순수 로직
└── <function-name>/
    ├── index.ts                 # Deno.serve, fetch, Storage/DB I/O만
    ├── <name>_classifier.ts     # 순수 검증/분류 로직 (Deno.serve 없음 → 테스트 가능)
    └── <name>_classifier.test.ts
```

## Workflow

```
1. 기존 함수 중 가장 비슷한 것 찾기
2. index.ts / 순수 로직 파일 분리 여부 결정
3. _shared/ 재사용 가능 여부 확인
4. 순수 로직 파일 설계 (스키마, 검증, reason code)
5. index.ts 설계 (I/O, 에러 매핑)
6. 구현
7. 테스트 작성
8. Flutter 쪽 연결 확인 (DataSource → Repository → Model → Entity)
9. 검증
```

### 1. 기존 함수 중 가장 비슷한 것 찾기

새 함수를 만들기 전에 `supabase/functions/` 아래 기존 함수(`analyze-message`, `analyze-document`, `send-notification` 등)를 먼저 읽는다. 같은 문제를 이미 다른 방식으로 풀어놓은 코드가 있는지 확인하고, 있으면 그 패턴을 따른다 — 새로운 구조를 임의로 만들지 않는다.

### 2. index.ts / 순수 로직 파일 분리

`index.ts`는 `Deno.serve(async (req) => {...})` 하나만 두고, 다음만 담당한다:

- CORS/메서드 체크, `verifyCaller(req)` 인증
- 외부 fetch(Anthropic 등)/Storage/DB 호출
- 순수 로직 파일이 반환한 결과를 조합해 응답 구성

실제 검증/분류/파싱 로직(비즈니스 규칙)은 `<name>_classifier.ts`처럼 별도 파일로 뺀다. 이유: `Deno.serve`가 모듈 import 시점에 리스너를 여는 side effect가 있어, 그 파일을 그대로 import하는 테스트는 작성할 수 없다. `analyze-message/risk_classifier.ts`, `analyze-document/document_classifier.ts`의 상단 주석이 이 이유를 설명한다.

### 3. _shared/ 재사용 확인

CORS, 인증, 공통 HTTP 응답 헬퍼는 이미 `_shared/`에 있다 — 새로 만들지 않는다. 두 개 이상의 함수가 동일한 결정론적 로직(예: 위험도 판정 규칙)을 필요로 하면, 그 로직만 `_shared/`로 추출하고 각 함수의 고유 로직(응답 필드 조합 등)은 각자 파일에 남긴다 — `_shared/risk_floor.ts`가 이 패턴의 예시다. 한 함수에서만 쓰는 로직을 미리 `_shared/`로 올리지 않는다.

### 4. 순수 로직 파일 설계

다음을 함께 설계한다:

- `SYSTEM_PROMPT`: 모델에게 전달할 지시. 사용자/문서 입력은 항상 "신뢰할 수 없는 데이터"로 명시하고, prompt injection 방어 문구를 포함한다 (기존 두 함수의 `SYSTEM_PROMPT` 참고).
- `CLASSIFY_TOOL`(또는 동등한 tool 스키마): `tool_choice`로 강제 호출해 구조화된 출력을 받는다.
- `parse*()` 함수: 모델이 반환한 tool input을 **절대 그대로 신뢰하지 않고** allowlist로 재검증한다. 실패 시 절대 안전한 기본값으로 fallback하지 않는다 — "AI 결과 없음" reason code를 반환한다 (`api.md`의 에러 처리 원칙과 동일한 정신).
- reason code 문자열: Flutter Repository가 `Failure`로 매핑할 수 있는 안정적인 문자열(`ai_provider_not_configured`, `ai_response_invalid` 등)로 정의한다 — 기존 함수들의 reason code 네이밍과 겹치지 않게, 그러나 같은 종류의 실패는 같은 이름을 재사용한다.

### 5. index.ts 설계

- 인증 실패, storage 실패, AI 실패, DB 실패를 각각 구분되는 reason code로 응답한다 (`json({ ok: false, reason }, status)`).
- 원본 이미지/민감 데이터를 다루면 `finally`에서 반드시 정리한다 (`analyze-document`의 storage 파일 삭제 참고).
- API 키는 `Deno.env.get(...)`로만 읽고, 코드에 하드코딩하지 않는다 (`git.md`).

### 6~7. 구현과 테스트

`testing.md`의 원칙을 그대로 따르되, Deno 대상이므로:

- 순수 로직 파일에 대해 `Deno.test`로 unit test를 작성한다 (검증 함수, 결정론적 규칙 등).
- **이 환경에는 Deno CLI가 없다.** 테스트 파일 상단에 기존 파일들과 동일하게 "NOT AVAILABLE: not executed in this environment" 주석을 남기고, 실행 여부를 사실대로 보고한다. 실행됐다고 거짓 보고하지 않는다.
- `Deno.serve` 부작용이 있는 `index.ts`는 직접 import하지 않는다.

### 8. Flutter 쪽 연결 확인

Edge Function 응답 필드를 바꾸거나 추가했으면, `apps/senior/lib/features/<feature>/data/models/*.dart`의 `fromJson`이 이미 그 필드를 다루는지 확인한다. 이미 model/entity/UI가 nullable 필드로 대비돼 있는 경우가 많으므로(예: `AnalysisResult.riskLevel`), Flutter 쪽을 임의로 먼저 고치지 말고 **먼저 읽어서** 실제로 변경이 필요한지 확인한다.

### 9. 검증

```
dart format .        # Flutter 쪽을 건드렸다면
flutter analyze
flutter test
```

Deno 테스트는 실행 불가 환경이면 "NOT AVAILABLE"로 명시하고, 실제 Anthropic API 검증이 필요하면 "실기기/실 API 환경에서 추가 검증 필요"라고 보고서에 남긴다.
