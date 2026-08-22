import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_my_profile_usecase.dart';
import '../../domain/usecases/save_profile_usecase.dart';

final profileRemoteDataSourceProvider = Provider(
  (ref) => ProfileRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

final getMyProfileUseCaseProvider = Provider(
  (ref) => GetMyProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final saveProfileUseCaseProvider = Provider(
  (ref) => SaveProfileUseCase(ref.watch(profileRepositoryProvider)),
);
