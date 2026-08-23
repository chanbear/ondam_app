import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/supabase_client_provider.dart';
import '../../data/datasources/demographics_remote_datasource.dart';
import '../../data/repositories/demographics_repository_impl.dart';
import '../../domain/repositories/demographics_repository.dart';
import '../../domain/usecases/get_my_demographics_usecase.dart';
import '../../domain/usecases/save_demographics_usecase.dart';

final demographicsRemoteDataSourceProvider = Provider(
  (ref) => DemographicsRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final demographicsRepositoryProvider = Provider<DemographicsRepository>((ref) {
  return DemographicsRepositoryImpl(
    ref.watch(demographicsRemoteDataSourceProvider),
  );
});

final getMyDemographicsUseCaseProvider = Provider(
  (ref) => GetMyDemographicsUseCase(ref.watch(demographicsRepositoryProvider)),
);

final saveDemographicsUseCaseProvider = Provider(
  (ref) => SaveDemographicsUseCase(ref.watch(demographicsRepositoryProvider)),
);
