# UI Research — 참고 앱/가이드라인 조사

> Phase 3 착수 전 UI/UX 설계 재정의 작업의 1단계 산출물. 실제 서비스/공식 가이드라인을 조사해 ONDAM Senior/Guardian 앱에 적용할 패턴과 적용하지 않을 패턴을 구분한다. **이 문서는 참고 앱을 그대로 복제하기 위한 자료가 아니라, ONDAM에 맞는 UX 원칙(`ui-principles.md`)을 도출하기 위한 근거 자료다.**
>
> 조사는 웹 검색을 통해 실제 서비스/공식 문서를 대상으로 진행했다. 각 항목에 출처를 남긴다. 일부 항목(네이버/카카오맵 시니어 기능, KakaoBank 시니어모드 상세, KRDS 정확한 픽셀값)은 검색 스니펫만으로는 신뢰할 만한 구체 수치를 확인하지 못해 "확인 필요"로 별도 표시했다 — 추측으로 채우지 않았다.

---

## Senior App 참고 조사

### 1. 고령층 대상 앱

**Toss — Universal Design / 큰글씨 모드** ([토스가 새롭게 상상하는 접근성 UX](https://toss.im/career/article/35281), [시니어 사용자가 어려워하는 UX 5가지](https://toss.tech/article/senior-usability-research), [토스 디자인 시스템](https://toss.tech/article/toss-design-system))
- 패턴: 토스는 시니어 사용자 730만 명 이상을 보유하며, 접근성을 "부가 기능"이 아니라 정보구조·흐름 전체의 재설계로 다룬다. 구체 사례: 큰글씨 모드에서 스크롤이 필요해진 긴 메뉴에 **위/아래 가장자리에 페이드/블러 그라데이션**을 넣어 "아래에 더 있다"는 것을 알아채게 했다(원래 시니어에게는 리스트 잘림 자체가 보이지 않는 문제였음). 또한 사용성 테스트에서 시니어는 가상의/추상적 과업 시나리오에 자신을 대입하는 것을 어려워한다는 것을 발견 — 막연한 시나리오보다 구체적이고 현실적인 시나리오로 테스트해야 훨씬 정확한 결과가 나온다.
- ONDAM 적용: **직접 적용** — "큰글씨/쉬운 모드"는 단순 폰트 확대가 아니라 스크롤/오버플로우 어포던스까지 재설계해야 한다는 근거.

**GrandPad(시니어 전용 태블릿)** ([SeniorSite 리뷰](https://seniorsite.org/resource/grandpad-tablet-review-simple-tech-that-actually-works-for-seniors/), [Argentum](https://www.argentum.org/grandpad-from-consumer-cellular-offers-senior-users-modern-features-with-simple-design/))
- 패턴: "90/90 보증" — 90세 사용자가 90초 안에 편안하게 쓸 수 있어야 한다는 설계 원칙. 앱은 최대 16개, 모두 중첩된 앱서랍 없이 홈 화면 하나에서 즉시 도달, 텍스트보다 아이콘 우선 네비게이션. 실제 시니어 자문단("Grand Advisors")과 지속적으로 테스트.
- ONDAM 적용: **부분 적용** — ONDAM Senior가 OS 전체 런처가 될 수는 없지만, "네비게이션 깊이를 최대한 평평하게, 핵심 기능까지 탭 수 최소화"라는 원칙은 쉬운 모드 홈 설계에 그대로 적용 가능.

### 2. 건강/공공서비스 앱

**KRDS — 대한민국 정부 디자인 시스템** ([krds.go.kr](https://www.krds.go.kr/), [개요](https://designcompass.org/2024/04/17/krds/))
- 패턴: 행정안전부가 발행한 공식 디자인 시스템. 디지털 취약계층(고령자/외국인/시각장애인)을 명시적으로 고려한 설계 원칙·스타일 가이드·컴포넌트·서비스 패턴 제공. 정부24/건강보험 사이트에 저시력 고령자를 위한 **복지·연금 정보 음성 안내** 기능이 최근 반영됨.
- ONDAM 적용: **강하게 적용, 1차 참고 자료로 채택** — ONDAM과 동일한 대상(공공/복지 정보를 다루는 고령 사용자)을 겨냥한 정부 공식 표준이라는 점에서 WCAG와 함께 가장 직접적인 참고 자료. 특히 `welfare_center`, 공문서 분석 결과 화면에서 어르신이 이미 신뢰하는 정부 서비스와 톤을 맞추는 데 유효.
- **확인 필요**: 컴포넌트 단위의 정확한 픽셀/색상 값은 검색 스니펫만으로 확인하지 못했다 — 실제 구현 시 KRDS 사이트를 직접 참고해 세부 수치를 재확인해야 한다.

**서울시 고령층 친화 디지털 접근성 표준 / 모바일 뱅킹 앱 고령자 모드 UX 평가(학술)** — 검색으로 존재는 확인했으나 원문 PDF를 직접 인출하지 못해 구체 수치를 이 문서에 반영하지 않았다. **확인 필요**(후속 조사 대상으로 남김).

### 3. 금융/은행 앱 접근성

- KakaoBank 시니어모드의 구체적 UI 스펙은 검색으로 확인하지 못했다 — **확인 필요**, 추측으로 기재하지 않는다.
- 다만 Toss 리서치와 일반 핀테크 UX 문헌에서 공통 확인된 사실: **로그인/인증 실패가 고령층 은행 앱의 가장 흔한 좌절 지점**이다. 시니어는 비밀번호/PIN을 정확히 입력했는데도 실패가 애매하게 느껴지는 경우("내가 잘못 친 건지, 뭔가 고장난 건지")가 많다.
- ONDAM 적용: **이미 Phase 2에서 반영됨** — PIN 오류 시 "PIN이 올바르지 않아요. (3회 실패)"처럼 구체적 안내를 하는 현재 구현 방향이 이 리서치와 정확히 일치한다. 앞으로도 "오류가 발생했습니다" 같은 모호한 문구를 쓰지 않는다는 원칙을 명문화한다.

### 4. 공공서비스 앱(폼/오류 패턴)

**GOV.UK Design System** ([Accessibility](https://design-system.service.gov.uk/accessibility/), [Patterns](https://design-system.service.gov.uk/patterns/))
- 패턴: 모든 컴포넌트를 자동 린팅이 아니라 **실제 보조기술로 WCAG 2.2 AA 검증**. 널리 인용되는 **오류 요약 패턴**(폼 상단에 오류 목록을 모아 보여주고, 각 항목이 문제 필드로 링크되며 포커스가 자동 이동)이 특히 유효. 정부 전체에서 통용되는 쉬운 언어(plain language) 콘텐츠 가이드 보유.
- ONDAM 적용: **적용** — 문서/문자 분석 결과나 온보딩 폼에서 "무엇이 문제였는지 + 어디를 고쳐야 하는지"를 한 곳에 모아 보여주는 컴포넌트(예: `AppAlertCard`)의 설계 근거로 채택.

### 5. 지도/길찾기 앱

Google Maps/Naver Map의 고령층 특화 단순화 기능은 이번 검색에서 구체적으로 인용 가능한 자료를 찾지 못했다 — **확인 필요**(후속 조사 대상), 추측으로 채우지 않는다.

### 6. 문서/카메라 기반 앱

**Google Lens / Google Camera 문서 모드**, **CamScanner "Turn Page to Auto Capture"** ([Android Police](https://www.androidpolice.com/2019/11/11/google-camera-document-scanning-photos-astrophotography-filter/), [CamScanner 기능 소개](https://thegadgetflow.com/blog/new-turn-page-to-auto-capture-feature-from-camscanner/), [Pixel Camera 지원](https://support.google.com/pixelcamera/answer/14271936?hl=en))
- 패턴: Google Lens는 뷰파인더 안에서 문서가 프레임에 잡히면 곧바로 "스캔하기" 어포던스를 보여주고, 이후 자르기 확인 단계로 넘어간다. CamScanner의 자동 촬영은 뷰파인더를 실시간 관찰해(흔들림/그림자 변화가 잦아드는 시점) **문서가 안정되면 자동으로 셔터를 누른다** — 사용자가 작은 셔터 버튼을 정확히 탭할 필요가 없다.
- 왜 중요한가: 손 떨림이 있거나 정밀한 탭이 어려운 고령 사용자에게 "작은 버튼을 정확히, 흔들림 없이 누르는 것" 자체가 실패 지점이 될 수 있다. 안정 시 자동 촬영은 이 정밀 동작 요구를 아예 없앤다.
- ONDAM 적용: **`document_scan`에 직접 적용 권장** — 실시간 프레임 가이드 오버레이 + 안정되면 자동 촬영, 단 **수동 촬영 버튼은 항상 함께 제공**(자동 촬영만 있으면 오작동 시 재시도 경로가 없음).

### 7. 음성 비서 앱

**Google Conversation Design 가이드라인** ([Confirmations](https://developers.google.com/assistant/conversation-design/confirmations), [VUI 원칙](https://design.google/library/speaking-the-same-language-vui))
- 패턴: 확인(confirmation)은 두 종류 — (a) 사용자가 말한/암시한 핵심 정보를 되짚어 확인, (b) 행동 완료 전/후 확인. **원칙: 오해의 비용이 클 때만 명시적으로 확인한다**(예: 데이터 삭제 전, 사용자 대신 무언가를 보낼 때 등) — 모든 것을 다 확인받으려 하는 것 자체가 나쁜 UX. 오류 복구는 딱딱한 에러 문구 대신 짧고 자연스러운 재질문("몇 명이라고 하셨죠?")을 사용.
- ONDAM 적용: **적용** — 음성 비서가 "정말 이대로 할까요?"를 물어야 하는 시점은 되돌리기 어렵거나 보호자에게 영향이 가는 행동(예: 보호자에게 알리기, 긴급 도움 호출)으로 한정하고, 단순 조회/이동성 명령("문자 확인해줘")에는 매번 확인받지 않는다.

### 8. 접근성 우선 앱 — 수치 기준

| 출처 | 항목 | 값 |
|---|---|---|
| Apple HIG | 최소 터치 영역 | **44×44 pt** |
| Material Design | 최소 터치 영역 | **48×48 dp**(약 9mm), 터치 영역 간 최소 8dp 간격 |
| WCAG 2.2 SC 2.5.8(AA, 2.2 신규) | 최소 터치 영역 | **24×24 CSS px**(또는 주변 24px 여백으로 대체 가능) |
| WCAG 2.2 SC 2.5.5(AAA) | 강화된 터치 영역 | **44×44 CSS px** |
| Apple HIG | 본문 텍스트 대비 | **4.5:1** 이상 |
| Apple HIG | 큰 텍스트 대비 | **3:1** 이상 |
| WCAG(엄격한 기준 문헌) | 본문 텍스트 대비 | 작은/비굵은 텍스트는 최대 **7:1**까지 권고, 18pt 이상 또는 14pt 굵게는 4.5:1 |
| WCAG | 비텍스트 UI(버튼/아이콘) 대비 | **3:1** 이상 |
| Apple HIG/일반 접근성 가이드 | 텍스트 확대 대응 | 레이아웃 붕괴 없이 **200%**까지 확대 지원 |

**ONDAM 토큰에 대한 시사점**: Apple의 44pt와 Material의 48dp가 "쾌적한" 범위의 상한/하한이고, WCAG 24px는 법적 최소선이지 목표치가 아니다. ONDAM Senior의 대상은 WCAG AAA에 준하는 요구를 갖는 경우가 많으므로 — **PIN 키패드의 기존 76px 버튼은 이미 모든 기준을 상회**(양호). 일반 버튼/리스트 행은 쉬운 모드에서 **최소 48dp, 권장 56~64dp**, 일반 모드는 Material 기준선인 48dp 근접을 목표로 한다. 대비는 **본문 4.5:1 / 큰 텍스트 3:1 / 비텍스트 컴포넌트 3:1**을 `AppColors` 대비 기준선으로 채택하고 라이트/다크 서페이스 양쪽에서 검증한다.

### 9. 신뢰도/불확실성 표현 (ONDAM "답변 신뢰도"에 직결)

여러 UX 패턴 자료가 공통적으로 수렴([reloadux.com](https://reloadux.com/blog/ai-uncertainty-trust-design-framework/), [AI UX Playground](https://aiuxplayground.com/pattern/confidence-score/), [Design Key](https://www.designkey.studio/post/designing-for-trust-ux-ai-features)):
- **비전문가에게 원시 퍼센트/확률을 절대 보여주지 않는다.** "87% 신뢰도" 대신 "높음/보통/낮음" 같은 평이한 언어의 단계형 표현을 쓴다.
- 비전문가가 실제로 필요로 하는 판단은 두 가지뿐이다: **(1) 이걸 믿고 행동해도 되는가, (2) 아니라면 어떻게 해야 하는가.** 신뢰도 UI는 이 두 가지에 반드시 답해야 하며, 단순 배지 표시로 끝나면 안 된다.
- 문서 파싱처럼 여러 필드가 있는 경우, 전체 하나의 점수보다 **필드별 신뢰도**(어떤 항목은 확실, 어떤 항목은 불확실)가 더 유용하다.
- 시각적 무게가 신뢰도와 매핑되어야 한다 — 신뢰도 높음=채도 있는/단색, 낮음=옅은/외곽선. **"낮은 신뢰도"에 빨강을 쓰지 않는다** — 빨강은 진짜 위험 신호(위험 문자 감지)에만 남겨두어야, "이 내용이 위험하다"와 "내가 이걸 잘 못 읽었을 수도 있다"가 혼동되지 않는다.
- ONDAM 적용: **기존 도메인 모델(`ReliabilityLevel`, 높음/보통/낮음 3단계)이 이미 이 리서치와 정확히 일치** — 구현 편의상 단순화한 것이 아니라 검증된 UX 관행이었음을 확인. 신뢰도 색상과 위험도 색상은 **반드시 별도 토큰 계열**로 분리해야 한다(이미 `ui-spec.md`에서 이 방향으로 정리되어 있었음 — 리서치로 재확인).

### 10. 고령층 대상 오류 메시지

여러 자료에서 공통 확인([UX Content Collective](https://uxcontent.com/how-to-write-error-messages/), [AgeTech UX 가이드](https://www.linkedin.com/pulse/guide-error-messages-user-guidance-agetech-ux-ezra-schwartz-vh07c)):
- **무슨 일이 있었는지 + 다음에 뭘 해야 하는지**를 함께 말한다. "오류가 발생했습니다"만으로 끝내지 않는다.
- 빈 화면이나 조용한 실패를 절대 만들지 않는다 — 네트워크 단절 시에도 "지금 무엇이 되고 무엇이 안 되는지"를 항상 알린다.
- 사용자가 복구 경로를 스스로 추측하게 하지 않고, 재시도/취소 같은 명시적 다음 행동을 제공한다.

---

## Guardian App 참고 조사

### 1. 가족/보호자 관리 앱

**Life360** ([life360.com](https://www.life360.com/learn/how-does-life360-work) / [Google Play](https://play.google.com/store/apps/details?id=com.life360.android.safetymapd) / [디자인 비평](https://medium.com/@JenniferWong_24131/life360-design-challenge-85e1dcc45aff))
- 패턴: 계층화된 알림 체계 — SOS(무음, 정확한 위치를 전체 서클+비상연락처에 즉시 전달), 충돌 감지(시속 40km 이상 충돌 시 자동 알림), 장소 알림(저장된 장소 도착/이탈), 배터리 알림, 경계(geofence) 이탈 알림. 청각/시각 장애가 있는 가족을 위해 **알림 전달 방식을 수신자별로 커스터마이즈**(화면 깜빡임/큰 경보음/진동 패턴)할 수 있음.
- 주목할 만한 비평: 성숙한 제품인 Life360조차 "지금 다들 괜찮은지"를 종합해서 보여주는 진짜 한눈 대시보드가 없다는 독립 디자인 리뷰의 지적이 있다 — 지도 + 개별 체크인에 의존하는 구조라는 것.
- ONDAM 적용: **위험 알림 아키텍처에 직접 적용**(이미 `technical-decisions.md`에서 "발송 채널 추상화"로 설계됨) — 동시에 반면교사: 보호자 홈이 "종합되지 않은 원시 이벤트 목록"으로 전락하지 않도록, 다른 무엇보다 먼저 "우리 어르신 지금 괜찮으신가?"에 한눈에 답하는 요약이 최상단에 있어야 한다.

**Google Family Link** ([families.google/familylink](https://families.google/familylink/), [2025년 2월 업데이트](https://blog.google/technology/families/family-link-updates-february-2025/))
- 패턴: 고정된 3개 영역(하이라이트/스크린타임, 통제, 위치) + 중앙 알림함으로 구성된 탭형 대시보드. 활동은 **요약**("어떤 앱을 얼마나")으로만 표시, 원시 로그가 아님. 최근 리뉴얼에서는 부모가 여러 화면을 돌아다니며 찾던 스크린타임 도구를 하나의 탭으로 통합 — 시간이 부족한 부모를 고려한 결정.
- ONDAM 적용: **적용** — 위험 알림/예정된 일정/고지서 통계처럼 **영역별로 구획된 홈**(하나의 긴 피드가 아니라)을 지지하는 근거.

**케어닥 케어옵스** ([기사](https://sports.khan.co.kr/article/202606180431003/))
- 패턴: 보호자가 어르신의 "실시간 건강 및 생활 상태"를 확인하되, 원시 센서 데이터가 아니라 단순화된 상태값으로 노출.
- ONDAM 적용: **부분 적용** — "가족에게는 요약 상태만 보여준다"는 접근이 국내 시장에서도 통용되는 패턴임을 확인.

### 2. 건강 모니터링 대시보드

**Apple Health — Sharing 기능** ([Apple Newsroom](https://www.apple.com/newsroom/2021/06/apple-advances-personal-health-by-introducing-secure-sharing-and-new-insights/), [Apple 지원](https://support.apple.com/en-us/HT212629))
- 패턴: "고령 부모가 자녀와 건강 데이터를 공유"하는 시나리오를 공식적으로 명시한 기능. 수신자(가족)의 화면은 **추세/인사이트 카드** 중심이고, 의미 있는 변화(활동량 급감, 심박 이상 등)가 있을 때만 푸시로 알린다 — 같은 알림이 당사자에게도 함께 간다.
- ONDAM 적용: **강하게 적용** — ONDAM 관계(원거리 가족이 부모를 확인)에 가장 가까운 실제 사례. Guardian의 "위험 알림 + 통계" 모델과 사실상 동일 구조.

**원격 환자 모니터링(RPM) 대시보드 일반** ([scnsoft.com](https://www.scnsoft.com/healthcare/medical-devices/remote-patient-monitoring), [thinkitive.com](https://www.thinkitive.com/blog/remote-patient-monitoring-software-development/))
- 인용할 만한 원칙: *"모든 것을 보여주는 대시보드는 아무도 쓰지 않는다... 적절한 것을, 적절한 시점에, 적절한 형태로 보여주는 대시보드만이 꼭 필요한 도구가 된다."*
- ONDAM 적용: **강하게 적용** — 보호자 홈 화면은 시간순이 아니라 **위험도순 정렬**로 설계해야 한다는 강한 근거.

### 3. 가족 안전/알림 등급

**고령자 모니터링 케어기버 대시보드 업계 자료** ([I'm Alive](https://imalive.co/elderly-monitoring-with-family-dashboard), [UX Team 케이스 스터디](https://www.uxteam.com/portfolio-item/caregiver-dashboard-for-managing-daily-care/))
- 반복 확인된 핵심 원칙: **"데이터가 너무 많으면 가족이 압도되고, 너무 적으면 계속 추측하게 된다."**
- 반복적으로 발견된 알림 등급 구조는 **3단계**다 — 고위험 → 직접 전화/강한 알림, 중위험 → 놓칠 수 없는 푸시, 저위험 → 조용한 SMS/로그 기록. 단순 "알림 있음/없음" 이진 구조가 아니다.
- 다중 보호자 접근: 접근 권한이 있는 모든 가족 구성원이 **동일하게 동기화된 상태**를 봐야 한다(기기별 로컬 상태가 아니라) — 누가 먼저 확인했는지에 따라 알림이 조용히 묻히는 일이 없도록. ONDAM의 1:N 어르신:보호자 모델과 직결.
- ONDAM 적용: **강하게 적용** — `RiskLevel`/알림 심각도를 UI에서 **이진(위험/안전)이 아니라 3단계**로 다루어야 한다는 근거이자, 보호자 홈이 "현재 상태 요약 + 최근 짧은 히스토리"로 시작하고 전체 분석 기록은 점진적 노출(탭해서 상세)로 넘겨야 한다는 근거.

### 4. 알림/대시보드 트리아지 설계

**Smashing Magazine — Notification UX Guidelines** ([링크](https://www.smashingmagazine.com/2025/07/design-guidelines-better-notifications-ux/)), **Toptal — Notification Design Guide** ([링크](https://www.toptal.com/designers/ux/notification-design))
- 핵심 원칙: 심각도는 **3단계**(high/medium/low)로 분류하고 유형(경고/확인/오류/성공/상태)을 그 위에 매핑한다. *"새 이벤트 타입을 추가할 때 기본값은 '알림 없음'이어야 하고, 알림을 추가하자고 제안하는 쪽이 그 필요성을 입증해야 한다."* 긴급 미만 이벤트는 묶어서(batch/digest) 전달.
- **Apple HIG — Notifications** ([링크](https://developer.apple.com/design/human-interface-guidelines/notifications)): 알림은 앱별 opt-in, 완전한 문장(잘림에 의존하지 않음), **같은 이벤트에 대해 중복 알림을 보내지 않는다**(반복 알림은 사용자가 앱 알림 자체를 끄게 만든다).
- ONDAM 적용: **강하게 적용** — 위험 알림=즉시 푸시(단독), 일정/통계 등 나머지=인앱 전용 또는 다이제스트라는 모델의 직접적 근거. 같은 위험 문자를 재분석/재시도해도 중복 푸시를 보내지 않는 규칙도 여기서 도출.

### 5. 통계/리포트 UX (비전문가 대상)

**가계부 앱 UX 패턴** ([onething.design](https://www.onething.design/post/budget-app-design), [appthetics.com](https://www.appthetics.com/blog/budgeting-apps-ux-patterns))
- 구체적 수치: 홈 화면은 **3~5개 핵심 정보**로 제한. 차트 유형은 용도별로 고정(한도/기준선=진행바, 추세=선그래프, 카테고리 비교=누적 막대, 전체 비중=파이차트만 — 파이차트는 항목이 많아지면 가독성이 떨어진다고 명시). 숫자는 탭하지 않아도 바로 보여야 한다. 주간 요약은 절대값보다 **추세/증감률**을 앞세운다.
- ONDAM 적용: **강하게 적용** — 고지서 통계 화면은 다중 차트 분석 페이지가 아니라 "추세 한 문장 + 단순 차트 1개" 구조로 설계.

### 6. 개인정보 공개 UX

**Google Family Link 공개 정책** ([보호자용 안내](https://families.google.com/familylink/privacy/notice), [자녀/청소년용 별도 안내](https://families.google/familylink/privacy/child-disclosure/))
- 패턴: Google은 "보호자가 무엇을 볼 수 있는지"뿐 아니라 **모니터링 대상(자녀)에게 무엇이 보이고 안 보이는지를 설명하는 별도 페이지**를 제공한다 — 단순 법적 고지가 아니라 자녀의 존엄성을 지키기 위한 장치로 프레이밍.
- ONDAM 적용: **강하게 적용, 현재 설계의 공백으로 플래그** — ONDAM은 "보호자가 무엇을 볼 수 있는지"(RLS, 화이트리스트)는 설계했지만, **어르신 쪽 화면에 "당신의 문자 원문은 보호자에게 보이지 않아요"를 명시적으로 보여주는 UI**는 아직 없다. 서버 정책만으로 끝내지 않고 Senior 앱에도 이 경계를 눈에 보이게 노출해야 한다.

### 7. 대시보드 일반 원칙

**UXPin 대시보드 가이드** ([링크](https://www.uxpin.com/studio/blog/dashboard-design-principles/)), **점진적 노출(Progressive Disclosure, Nielsen 1995 계열 문헌**([링크](https://uxuiprinciples.com/en/principles/progressive-disclosure)))
- **점진적 노출**: 핵심 요약만 먼저 보여주고, 상세는 사용자가 파고들 때만 노출. 요약 데이터는 집계된 형태라 로딩이 빠르고, 상세는 필요할 때만 조회 — UX뿐 아니라 실제 쿼리 설계(요약 vs 상세를 다른 Repository 조회로 분리)에도 유효한 원칙.
- **의미론적 색상 규율**: 빨강은 "지금 반드시 행동해야 함"에만 엄격히 예약한다 — 진짜 긴급이 아닌 곳에 경고색을 남발하면 경고 피로(alert fatigue)가 생기고 신호에 대한 신뢰가 떨어진다.
- ONDAM 적용: 전용 `AppRiskBadge`/`AppAlertCard` 색상 계약이 **오직 진짜 위험도에만** 쓰이고, 중립 정보나 신뢰도 표시에 재사용되지 않아야 한다는 근거(Senior 리서치 9번의 신뢰도/위험도 색상 분리 원칙과 대칭).

### Guardian 조사 종합: 반복적으로 확인된 패턴

1. 홈 화면은 시간순이 아니라 **위험도순 정렬**, 항목은 3~5개로 제한, 최상단은 "지금 괜찮으신가"에 답하는 종합 요약.
2. 알림 심각도는 **3단계**(고/중/저)로 다루되, 푸시 발송 여부는 **2단계**로 단순화(위험=즉시 푸시, 나머지=인앱/다이제스트)한다 — 표시는 3단계, 발송 정책은 2단계로 분리.
3. 위험 등급 색상은 **빨강=긴급, 주황/노랑=주의, 초록/중립=정상**이 업계 공통 관례 — 새로 발명할 필요 없음. 단, 신뢰도 표시 색상과는 분리된 계열을 쓴다.
4. 원시 데이터 대신 **요약/추세 카드**를 항상 우선한다(Apple Health, 가계부 앱, RPM 대시보드 공통). **점진적 노출**로 상세는 탭해서.
5. **같은 이벤트에 중복 알림 금지**(Apple HIG).
6. 여러 보호자가 있을 때 **동기화된 동일 상태**를 봐야 한다(1:N 구조 대응).
7. 개인정보 경계는 **서버 정책만이 아니라 어르신 쪽 UI에도 명시적으로 노출**해야 한다(현재 설계 공백).

---

## 적용하지 않을 패턴 (명시적 제외)

- Life360/RPM 등 기업/보안 대시보드의 **5단계 이상 세분화된 긴급도 체계** — ONDAM Guardian은 소비자 가족 앱 관례를 따라 표시는 3단계, 푸시 발송 정책은 2단계로 유지한다.
- 가계부 앱의 **파이차트 다중 사용** — 항목이 늘어나면 가독성이 떨어진다는 지적을 그대로 받아들여, 고지서 통계에서는 파이차트를 기본으로 채택하지 않는다.
- 신뢰도 표시에 **원시 퍼센트/확률 노출** — 어떤 참고 자료도 비전문가 대상 UI에서 숫자 노출을 권장하지 않았다. 기존 결정("높음/보통/낮음")을 그대로 유지.
- 자동 촬영을 **수동 촬영 버튼 없이** 단독으로 제공하는 것 — CamScanner류도 항상 수동 대안을 남겨둔다.
- 참고 앱들의 **시각적 스타일(색/폰트/레이아웃)을 그대로 복제하는 것** — 이 문서에서 추출하는 것은 정보구조·상호작용 패턴이며, 실제 색상/타이포는 `packages/design_system` 토큰과 향후 Figma 작업을 따른다.

## 확인 필요 (후속 조사 대상, 이번 라운드에서 확정하지 않음)

- Naver Map/Kakao Map의 고령층 특화 단순화 기능 상세.
- KakaoBank 등 국내 은행 앱 시니어모드의 정확한 UI 스펙.
- KRDS 컴포넌트 단위 정확한 픽셀/색상 값(사이트 직접 열람 필요).
- 서울시 고령층 친화 디지털 접근성 표준의 구체 수치(PDF 원문 확인 필요).
