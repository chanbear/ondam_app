# ui-design.md — 디자인 시스템 규칙

## 토큰 위치

```
lib/app/theme/
├── app_theme.dart        # ThemeData 조립 (light/dark)
├── app_colors.dart        # 색상 토큰
├── app_text_styles.dart   # 타이포그래피 토큰
├── app_spacing.dart       # spacing 스케일 (xs/sm/md/lg/xl/xxl)
└── app_radius.dart        # radius 스케일 (sm/md/lg/xl/full)
```

## 색상

- `Color(0xFF...)`를 위젯 코드에 직접 쓰지 않는다. 항상 `AppColors.xxx`를 사용한다.
- 새 색상이 필요하면 `app_colors.dart`에 의미 있는 이름으로 추가한다 (예: `AppColors.accent`). 위젯 파일 안에서 지역 색상 상수를 만들지 않는다.
- 다크모드 대응 색상(`backgroundDark`, `surfaceDark` 등)은 `AppTheme.dark`를 통해서만 적용한다. 위젯에서 `Theme.of(context).brightness`로 직접 분기하지 않는다.

## Typography

- `TextStyle(fontSize: .., ...)`를 직접 만들지 않는다. `AppTextStyles.xxx`를 사용한다.
- 새 스타일이 필요하면 `app_text_styles.dart`에 추가한다.

## Spacing / Radius

- `SizedBox(height: 16)`처럼 숫자를 직접 쓰지 않는다. `SizedBox(height: AppSpacing.md)`처럼 토큰을 사용한다.
- `BorderRadius.circular(8)`도 마찬가지로 `AppRadius.md`를 사용한다.

## Responsive UI

- 고정 픽셀 크기 대신 `MediaQuery`, `LayoutBuilder`, `Expanded`/`Flexible`을 우선 사용한다.
- `SafeArea`로 노치/시스템 UI를 항상 고려한다.
- 텍스트는 시스템 폰트 크기 확대(`textScaler`)를 깨지 않는 방식으로 배치한다 — 고정 높이 컨테이너에 텍스트를 억지로 맞추지 않는다.

## Accessibility

- 탭 가능한 요소는 최소 44x44 논리 픽셀 터치 영역을 확보한다.
- 의미 전달이 색상에만 의존하지 않게 한다 (예: 에러는 색상 + 아이콘/텍스트 병행).
- 이미지/아이콘 버튼에는 `Semantics`/`tooltip` 등으로 스크린 리더가 읽을 수 있는 설명을 제공한다.
- 텍스트 대비는 배경 대비 WCAG AA 기준(일반 텍스트 4.5:1)을 참고해 `AppColors` 토큰을 고른다.

## 공통 Widget

- 두 개 이상의 feature가 실제로 공유하는 위젯만 `lib/core/widgets/`에 둔다 (현재: `AppButton`, `AppLoading`, `AppError`).
- 특정 feature에서만 쓰는 위젯은 `features/<feature>/presentation/widgets/`에 둔다.
- 사용 범위가 불확실하면 일단 feature 내부에 두고, 실제로 재사용이 발생할 때 core로 승격한다.

## UI와 business logic 분리

- Widget의 `build()` 안에서 비즈니스 규칙(할인 계산, 유효성 검증 로직 등)을 작성하지 않는다 — UseCase/Provider로 옮긴다.
- Widget은 Provider가 넘겨준 상태를 그리는 역할만 한다.

## 기존 UI 분석 방식 (Figma 없이)

기존 온담앱 화면(캡처, 녹화, APK, 실제 실행 화면)을 참고할 때는 다음을 먼저 추출한다:

```
화면 구조 / 레이아웃 / 색상 / 폰트 / spacing / radius / icon / image / navigation / component / 상태별 UI
```

추출한 값은 임의로 재해석하지 않고 위 토큰 체계(`AppColors`/`AppTextStyles`/`AppSpacing`/`AppRadius`)에 맞춰 매핑한다. 기존 값이 토큰 스케일과 어긋나면(예: spacing 13px) 가장 가까운 토큰으로 근사하고 그 이유를 남긴다.
