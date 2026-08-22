import 'package:ondam_core/ondam_core.dart';

import '../entities/region.dart';

/// The elder's saved [Region] — persisted per-user so it survives across
/// sessions and can drive `welfare_center`'s search without asking again
/// every time (ONDAM 2.0 요구사항 31). A `null` value (inside [Ok]) is a
/// valid, honest "not set yet" state, not an error.
abstract class RegionRepository {
  Future<Result<Region?>> getMyRegion();

  Future<Result<void>> saveRegion(Region region);
}
