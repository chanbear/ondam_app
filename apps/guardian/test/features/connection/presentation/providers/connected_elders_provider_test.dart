import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/connected_elders_provider.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/my_links_notifier.dart';
import 'package:ondam_models/ondam_models.dart';

GuardianLink _link(String elderId, GuardianLinkStatus status) {
  return GuardianLink(
    id: 'link-$elderId',
    elderId: elderId,
    guardianId: 'guardian-1',
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

class _FixedMyLinksNotifier extends MyLinksNotifier {
  _FixedMyLinksNotifier(this._links);

  final List<GuardianLink> _links;

  @override
  Future<List<GuardianLink>> build() async => _links;
}

ProviderContainer _containerWithLinks(List<GuardianLink> links) {
  return ProviderContainer(
    overrides: [
      myLinksProvider.overrideWith(() => _FixedMyLinksNotifier(links)),
    ],
  );
}

void main() {
  test('연결된 어르신이 0명이면 빈 목록을 반환한다', () async {
    final container = _containerWithLinks(const []);
    addTearDown(container.dispose);
    await container.read(myLinksProvider.future);

    expect(container.read(connectedEldersProvider), isEmpty);
  });

  test('accepted 상태인 링크 1개만 있으면 어르신 1명을 반환한다', () async {
    final container = _containerWithLinks([
      _link('elder-1', GuardianLinkStatus.accepted),
    ]);
    addTearDown(container.dispose);
    await container.read(myLinksProvider.future);

    final elders = container.read(connectedEldersProvider);
    expect(elders, hasLength(1));
    expect(elders.single.id, 'elder-1');
  });

  test('accepted 링크가 2개 이상이면 전부 반환한다', () async {
    final container = _containerWithLinks([
      _link('elder-1', GuardianLinkStatus.accepted),
      _link('elder-2', GuardianLinkStatus.accepted),
    ]);
    addTearDown(container.dispose);
    await container.read(myLinksProvider.future);

    expect(container.read(connectedEldersProvider), hasLength(2));
  });

  test('pending 링크는 연결된 어르신 목록에서 제외한다', () async {
    final container = _containerWithLinks([
      _link('elder-1', GuardianLinkStatus.pending),
      _link('elder-2', GuardianLinkStatus.accepted),
    ]);
    addTearDown(container.dispose);
    await container.read(myLinksProvider.future);

    final elders = container.read(connectedEldersProvider);
    expect(elders, hasLength(1));
    expect(elders.single.id, 'elder-2');
  });

  test('revoked 링크는 연결된 어르신 목록에서 제외한다', () async {
    final container = _containerWithLinks([
      _link('elder-1', GuardianLinkStatus.revoked),
      _link('elder-2', GuardianLinkStatus.accepted),
    ]);
    addTearDown(container.dispose);
    await container.read(myLinksProvider.future);

    final elders = container.read(connectedEldersProvider);
    expect(elders, hasLength(1));
    expect(elders.single.id, 'elder-2');
  });

  test('rejected 링크는 연결된 어르신 목록에서 제외한다', () async {
    final container = _containerWithLinks([
      _link('elder-1', GuardianLinkStatus.rejected),
    ]);
    addTearDown(container.dispose);
    await container.read(myLinksProvider.future);

    expect(container.read(connectedEldersProvider), isEmpty);
  });

  test('표시 이름은 실제 elderId에서 유도한 값이며 임의 문자열이 아니다', () async {
    final container = _containerWithLinks([
      _link('elder-abcdef12-3456', GuardianLinkStatus.accepted),
    ]);
    addTearDown(container.dispose);
    await container.read(myLinksProvider.future);

    final elder = container.read(connectedEldersProvider).single;
    expect(elder.name, contains('elder-ab'));
  });
}
