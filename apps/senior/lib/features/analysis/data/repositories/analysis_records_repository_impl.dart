import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/analysis_records_repository.dart';
import '../datasources/analysis_records_remote_datasource.dart';
import '../models/analysis_result_model.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as Guardian's `AnalysisRepositoryImpl` (api.md Repository responsibility).
class AnalysisRecordsRepositoryImpl implements AnalysisRecordsRepository {
  const AnalysisRecordsRepositoryImpl(this._dataSource);

  final AnalysisRecordsRemoteDataSource _dataSource;

  @override
  Future<Result<List<AnalysisResult>>> getMyRecords() async {
    try {
      final rows = await _dataSource.fetchMine();
      return Ok(
        rows
            .map((row) => AnalysisResultModel.fromJson(row).toEntity())
            .toList(),
      );
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> confirm(String analysisResultId) async {
    try {
      await _dataSource.confirm(analysisResultId);
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
