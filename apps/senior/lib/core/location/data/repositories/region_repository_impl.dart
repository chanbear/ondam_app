import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/region.dart';
import '../../domain/repositories/region_repository.dart';
import '../datasources/region_remote_datasource.dart';
import '../models/region_model.dart';

/// Same exception→Failure mapping pattern as
/// `AnalysisRecordsRepositoryImpl` (api.md Repository responsibility).
class RegionRepositoryImpl implements RegionRepository {
  const RegionRepositoryImpl(this._dataSource);

  final RegionRemoteDataSource _dataSource;

  @override
  Future<Result<Region?>> getMyRegion() async {
    try {
      final row = await _dataSource.fetchMine();
      return Ok(RegionModel.fromRow(row)?.toEntity());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> saveRegion(Region region) async {
    try {
      await _dataSource.upsertMine(
        sido: region.sido,
        sigungu: region.sigungu,
        dong: region.dong,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Failure _mapPostgrestException(PostgrestException e) {
    if (e.code == 'PGRST301' || e.code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
