import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/analysis_remote_datasource.dart';
import '../../data/repositories/analysis_repository_impl.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../../domain/usecases/get_analysis_records_usecase.dart';

// Dependency injection wiring only — no business logic (riverpod.md).

final analysisRemoteDataSourceProvider = Provider<AnalysisRemoteDataSource>((
  ref,
) {
  return AnalysisRemoteDataSource(ref.watch(supabaseClientProvider));
});

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepositoryImpl(ref.watch(analysisRemoteDataSourceProvider));
});

final getAnalysisRecordsUseCaseProvider = Provider(
  (ref) => GetAnalysisRecordsUseCase(ref.watch(analysisRepositoryProvider)),
);
