import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/schedule_remote_datasource.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/usecases/create_schedule_usecase.dart';
import '../../domain/usecases/get_my_schedules_usecase.dart';

// Dependency injection wiring only — no business logic (riverpod.md).

final scheduleRemoteDataSourceProvider = Provider<ScheduleRemoteDataSource>((
  ref,
) {
  return ScheduleRemoteDataSource(ref.watch(supabaseClientProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.watch(scheduleRemoteDataSourceProvider));
});

final getMySchedulesUseCaseProvider = Provider((ref) {
  return GetMySchedulesUseCase(ref.watch(scheduleRepositoryProvider));
});

final createScheduleUseCaseProvider = Provider((ref) {
  return CreateScheduleUseCase(ref.watch(scheduleRepositoryProvider));
});
