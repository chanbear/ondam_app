import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/schedule_remote_datasource.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/usecases/get_schedules_for_elder_usecase.dart';

// Dependency injection wiring only — no business logic (riverpod.md).

final scheduleRemoteDataSourceProvider = Provider<ScheduleRemoteDataSource>((
  ref,
) {
  return ScheduleRemoteDataSource(ref.watch(supabaseClientProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.watch(scheduleRemoteDataSourceProvider));
});

final getSchedulesForElderUseCaseProvider = Provider((ref) {
  return GetSchedulesForElderUseCase(ref.watch(scheduleRepositoryProvider));
});
