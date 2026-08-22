import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import 'my_links_notifier.dart';

/// 연결된 어르신 목록 — Phase 5의 실제 `guardian_links` Repository
/// (`myLinksProvider`)를 소스로 사용한다. `accepted` 상태만 "연결된
/// 어르신"으로 취급하고, pending/rejected/revoked는 제외한다(Phase 6 지시
/// 3-1 및 technical-decisions.md §1-6).
///
/// 어르신 표시 이름을 보여줄 `users`/`profile` 테이블이 아직 없어(Phase 3
/// v8부터 알려진 제약, 이번 Phase에서도 해소되지 않음) 실제 이름을 만들 수
/// 없다 — 임의 문자열을 지어내는 대신, 실제 데이터(elder_id)에서 유도한
/// 안전한 대체 표현("어르신 (앞 8자리 ID)")을 사용한다. `connection`
/// feature의 `ConnectionListPage`가 이미 쓰는 것과 동일한 표현이다.
final connectedEldersProvider = Provider<List<ElderSummary>>((ref) {
  final links = ref.watch(myLinksProvider).value ?? const <GuardianLink>[];
  return links
      .where((link) => link.status == GuardianLinkStatus.accepted)
      .map(
        (link) => ElderSummary(
          id: link.elderId,
          name: '어르신 (${_shortId(link.elderId)})',
        ),
      )
      .toList();
});

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

/// 현재 선택된 어르신 — 비즈니스 로직 없는 단순 UI 상태(riverpod.md:
/// "단순한 UI 로컬 상태... 비즈니스 로직이 없는 원시 상태에만 사용"). Riverpod
/// 3에서 `StateProvider`는 `legacy.dart` import가 필요한 레거시 API로
/// 옮겨졌으므로, 이 프로젝트의 다른 단순 상태(`pinVerifiedProvider`,
/// `easyModeProvider`)와 동일하게 최소 `Notifier`로 구현한다.
class SelectedElderIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String elderId) => state = elderId;
}

final selectedElderIdProvider =
    NotifierProvider<SelectedElderIdNotifier, String?>(
      SelectedElderIdNotifier.new,
    );

/// PHASE 37 버그 수정: [selectedElderIdProvider]는 사용자가 실제로
/// `AppElderSwitcher`를 조작해야만 값이 채워지는데, `AppElderSwitcher`는
/// 어르신이 1명뿐이면 선택 UI 자체를 숨긴다(선택할 것이 없으므로) — 그
/// 결과 어르신이 1명만 연결된, 가장 흔한 경우에 `selectedElderIdProvider`가
/// 앱을 새로 켤 때마다 계속 null로 남아 이를 직접 watch하는
/// `analysisRecordsProvider`가 항상 빈 목록을 반환하고 있었다(홈/기록/통계
/// 탭 전부 영향). `SelectedElderIdNotifier.build()`가 직접
/// `connectedEldersProvider`를 기본값으로 watch하게 만들면 사용자가 이미
/// 명시적으로 선택한 어르신이 있어도 `connectedEldersProvider`가 재계산될
/// 때마다(예: 새 어르신이 연결) 그 선택이 조용히 리셋되는 부작용이 생긴다
/// (Notifier.build()가 자신이 watch하는 provider가 바뀌면 처음부터 다시
/// 실행되기 때문). 그래서 상태 자체는 건드리지 않고, "명시적 선택이
/// 있으면 그것을, 없으면 목록의 첫 어르신을" 계산하는 순수 파생 Provider로
/// 분리한다 — 명시적 선택은 항상 그대로 보존된다.
final effectiveSelectedElderIdProvider = Provider<String?>((ref) {
  final explicit = ref.watch(selectedElderIdProvider);
  if (explicit != null) return explicit;
  final elders = ref.watch(connectedEldersProvider);
  return elders.isEmpty ? null : elders.first.id;
});
