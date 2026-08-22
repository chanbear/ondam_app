import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/supabase_client_provider.dart';
import '../../data/datasources/location_datasource.dart';
import '../../data/datasources/location_permission_datasource.dart';
import '../../data/datasources/region_remote_datasource.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/region_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/region_repository.dart';
import '../../domain/usecases/check_location_permission_usecase.dart';
import '../../domain/usecases/get_current_region_usecase.dart';
import '../../domain/usecases/get_my_region_usecase.dart';
import '../../domain/usecases/request_location_permission_usecase.dart';
import '../../domain/usecases/save_region_usecase.dart';

final locationPermissionDataSourceProvider = Provider(
  (ref) => LocationPermissionDataSource(),
);

final locationDataSourceProvider = Provider((ref) => LocationDataSource());

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    ref.watch(locationPermissionDataSourceProvider),
    ref.watch(locationDataSourceProvider),
  );
});

final regionRemoteDataSourceProvider = Provider(
  (ref) => RegionRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final regionRepositoryProvider = Provider<RegionRepository>((ref) {
  return RegionRepositoryImpl(ref.watch(regionRemoteDataSourceProvider));
});

final checkLocationPermissionUseCaseProvider = Provider(
  (ref) =>
      CheckLocationPermissionUseCase(ref.watch(locationRepositoryProvider)),
);

final requestLocationPermissionUseCaseProvider = Provider(
  (ref) =>
      RequestLocationPermissionUseCase(ref.watch(locationRepositoryProvider)),
);

final getCurrentRegionUseCaseProvider = Provider(
  (ref) => GetCurrentRegionUseCase(ref.watch(locationRepositoryProvider)),
);

final getMyRegionUseCaseProvider = Provider(
  (ref) => GetMyRegionUseCase(ref.watch(regionRepositoryProvider)),
);

final saveRegionUseCaseProvider = Provider(
  (ref) => SaveRegionUseCase(ref.watch(regionRepositoryProvider)),
);
