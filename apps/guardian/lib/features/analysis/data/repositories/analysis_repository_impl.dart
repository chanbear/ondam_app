import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/analysis_repository.dart';
import '../datasources/analysis_remote_datasource.dart';
import '../models/analysis_result_model.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as `ConnectionRepositoryImpl` (api.md Repository responsibility).
class AnalysisRepositoryImpl implements AnalysisRepository {
  const AnalysisRepositoryImpl(this._dataSource);

  final AnalysisRemoteDataSource _dataSource;

  @override
  Future<Result<List<AnalysisResult>>> getRecordsForElder(
    String elderId,
  ) async {
    try {
      final rows = await _dataSource.fetchForElder(elderId);
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

  Failure _mapPostgrestException(PostgrestException e) {
    if (e.code == 'PGRST301' || e.code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
