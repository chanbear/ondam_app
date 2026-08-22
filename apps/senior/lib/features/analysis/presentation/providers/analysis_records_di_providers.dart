import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/analysis_records_remote_datasource.dart';
import '../../data/repositories/analysis_records_repository_impl.dart';
import '../../domain/repositories/analysis_records_repository.dart';
import '../../domain/usecases/confirm_analysis_result_usecase.dart';
import '../../domain/usecases/get_my_analysis_records_usecase.dart';

// Dependency injection wiring only — no business logic (riverpod.md).

final analysisRecordsRemoteDataSourceProvider =
    Provider<AnalysisRecordsRemoteDataSource>((ref) {
      return AnalysisRecordsRemoteDataSource(ref.watch(supabaseClientProvider));
    });

final analysisRecordsRepositoryProvider = Provider<AnalysisRecordsRepository>((
  ref,
) {
  return AnalysisRecordsRepositoryImpl(
    ref.watch(analysisRecordsRemoteDataSourceProvider),
  );
});

final getMyAnalysisRecordsUseCaseProvider = Provider((ref) {
  return GetMyAnalysisRecordsUseCase(
    ref.watch(analysisRecordsRepositoryProvider),
  );
});

final confirmAnalysisResultUseCaseProvider = Provider((ref) {
  return ConfirmAnalysisResultUseCase(
    ref.watch(analysisRecordsRepositoryProvider),
  );
});
