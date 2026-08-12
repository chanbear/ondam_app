# flutter.md — Dart/Flutter 코딩 규칙

## Naming

- 파일명: `snake_case.dart`
- 클래스/enum/typedef: `PascalCase`
- 변수/함수/파라미터: `camelCase`
- private 멤버: `_camelCase`
- Provider 변수: `xxxProvider` (예: `dioClientProvider`, `appRouterProvider`)
- 상수: `camelCase` + `static const` (Dart는 `SCREAMING_CASE`를 쓰지 않음)

## Null Safety

- `!` (non-null assertion)는 최후의 수단. 값이 없을 수 있으면 타입에 `?`를 명시하고 분기 처리한다.
- `late`는 "반드시 build 이전에 초기화된다"는 확신이 있을 때만 사용한다. 확신이 없으면 nullable + 기본값으로 처리한다.

## async/await

- `Future`를 반환하는 함수는 항상 `async`/`await`로 작성한다. `.then()` 체이닝은 여러 단계가 얽힐 때만 예외적으로 허용.
- `BuildContext`를 `await` 이후에 사용할 때는 `context.mounted`를 확인한다.
- fire-and-forget이 의도된 게 아니라면 `Future`를 무시하지 않는다 (`unawaited()`로 의도를 명시).

## Widget 작성

- Widget은 하나의 책임만 가진다. 화면(Page)과 구성요소(Widget)를 분리하고, Page는 조립만 담당한다.
- 300줄을 넘는 `build()`는 하위 Widget으로 분리 신호로 본다.
- `StatelessWidget` + Riverpod `ConsumerWidget`을 기본으로 사용. `StatefulWidget`은 로컬 UI 상태(애니메이션 컨트롤러, 텍스트 컨트롤러 등)에만 사용한다.
- 재사용 가능한 상수 위젯은 `const` 생성자를 유지한다.

## 가독성

- 매직 넘버/문자열을 그대로 쓰지 않는다 — 의미 있는 이름의 상수나 `lib/app/theme/` 토큰을 사용한다.
- import는 `dart:`, `package:flutter/...`, 외부 package, 상대경로(`../`) 순으로 정렬한다.
- 주석은 "왜"가 비직관적일 때만 작성한다. 코드가 "무엇을" 하는지 설명하는 주석은 쓰지 않는다.

## 참고

색상/spacing/타이포그래피 토큰, 공통 위젯 배치 기준은 `ui-design.md` 참고.
