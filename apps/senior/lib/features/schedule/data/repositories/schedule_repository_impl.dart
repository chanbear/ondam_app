import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';
import '../models/schedule_model.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as `AnalysisRecordsRepositoryImpl` (api.md Repository responsibility).
class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(this._dataSource);

  final ScheduleRemoteDataSource _dataSource;

  @override
  Future<Result<List<Schedule>>> getMySchedules() async {
    try {
      final rows = await _dataSource.fetchMine();
      return Ok(
        rows.map((row) => ScheduleModel.fromJson(row).toEntity()).toList(),
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
  Future<Result<void>> createSchedule({
    required String title,
    required DateTime scheduledAt,
    required bool isRecurring,
    int? recurrenceHour,
    int? recurrenceMinute,
  }) async {
    try {
      await _dataSource.create(
        title: title,
        scheduledAt: scheduledAt,
        isRecurring: isRecurring,
        recurrenceHour: recurrenceHour,
        recurrenceMinute: recurrenceMinute,
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

  @override
  Future<Result<void>> toggleCompleted(String id, bool completed) async {
    try {
      await _dataSource.toggleCompleted(id, completed);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> deleteSchedule(String id) async {
    try {
      await _dataSource.delete(id);
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
