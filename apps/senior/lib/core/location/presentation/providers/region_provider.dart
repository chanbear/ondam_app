import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/region.dart';
import 'location_di_providers.dart';

/// The elder's saved region — `profile`(입력/저장)와 `welfare_center`(검색
/// 조건으로 읽기) feature가 함께 구독하는 공유 상태이므로 core에 둔다
/// (architecture.md "공유가 필요한 도메인 개념은 core로 분리").
class RegionNotifier extends AsyncNotifier<Region?> {
  @override
  Future<Region?> build() async {
    final result = await ref.read(getMyRegionUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Result<void>> save(Region region) async {
    final result = await ref.read(saveRegionUseCaseProvider).call(region);
    if (result case Ok()) {
      // 요청에 쓴 값을 그대로 믿고 상태에 반영하지 않는다 — 서버에 실제로
      // 반영됐는지 다시 조회해서 확인한다(ONDAM 2.0 요구사항 31 "저장 후
      // 재조회"). upsert 자체가 성공해도 서버 쪽에서 값이 예상과 다르게
      // 정규화될 가능성을 배제하지 않는다.
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}

final regionProvider = AsyncNotifierProvider<RegionNotifier, Region?>(
  RegionNotifier.new,
);
