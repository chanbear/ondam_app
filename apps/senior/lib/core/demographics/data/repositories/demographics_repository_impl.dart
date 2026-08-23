import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/demographics.dart';
import '../../domain/repositories/demographics_repository.dart';
import '../datasources/demographics_remote_datasource.dart';
import '../models/demographics_model.dart';

/// `RegionRepositoryImpl`과 동일한 예외→Failure 매핑 패턴(api.md).
class DemographicsRepositoryImpl implements DemographicsRepository {
  const DemographicsRepositoryImpl(this._dataSource);

  final DemographicsRemoteDataSource _dataSource;

  @override
  Future<Result<Demographics?>> getMyDemographics() async {
    try {
      final row = await _dataSource.fetchMine();
      return Ok(DemographicsModel.fromRow(row)?.toEntity());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> saveDemographics(Demographics demographics) async {
    try {
      await _dataSource.upsertMine(
        age: demographics.age!,
        gender: demographics.gender!.value,
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
