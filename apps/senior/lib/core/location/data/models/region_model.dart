import '../../domain/entities/region.dart';

/// DTO for a `users` row's region columns. `fromRow` returns `null` when the
/// row has no region set yet (fresh user) — a valid "not set" state, not a
/// parse error.
class RegionModel {
  const RegionModel({
    required this.sido,
    required this.sigungu,
    required this.dong,
  });

  final String sido;
  final String sigungu;
  final String dong;

  static RegionModel? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final sido = row['region_sido'] as String?;
    final sigungu = row['region_sigungu'] as String?;
    final dong = row['region_dong'] as String?;
    if (sido == null || sido.isEmpty) return null;
    return RegionModel(sido: sido, sigungu: sigungu ?? '', dong: dong ?? '');
  }

  Region toEntity() => Region(sido: sido, sigungu: sigungu, dong: dong);
}
