import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/pin_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/add_role_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/get_roles_usecase.dart';
import '../../domain/usecases/has_pin_usecase.dart';
import '../../domain/usecases/reset_pin_usecase.dart';
import '../../domain/usecases/set_pin_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/verify_pin_usecase.dart';

// Dependency injection wiring only — no business logic here (riverpod.md:
// "Repository/UseCase는 생성자에서 직접 의존성을 new하지 않고 Provider를
// 통해 주입받는다").

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(supabaseClientProvider));
});

final pinRemoteDataSourceProvider = Provider<PinRemoteDataSource>((ref) {
  return PinRemoteDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authDataSource: ref.watch(authRemoteDataSourceProvider),
    pinDataSource: ref.watch(pinRemoteDataSourceProvider),
  );
});

final signUpUseCaseProvider = Provider(
  (ref) => SignUpUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

final setPinUseCaseProvider = Provider(
  (ref) => SetPinUseCase(ref.watch(authRepositoryProvider)),
);

final verifyPinUseCaseProvider = Provider(
  (ref) => VerifyPinUseCase(ref.watch(authRepositoryProvider)),
);

final resetPinUseCaseProvider = Provider(
  (ref) => ResetPinUseCase(ref.watch(authRepositoryProvider)),
);

final hasPinUseCaseProvider = Provider(
  (ref) => HasPinUseCase(ref.watch(authRepositoryProvider)),
);

final deleteAccountUseCaseProvider = Provider(
  (ref) => DeleteAccountUseCase(ref.watch(authRepositoryProvider)),
);

final addRoleUseCaseProvider = Provider(
  (ref) => AddRoleUseCase(ref.watch(authRepositoryProvider)),
);

final getRolesUseCaseProvider = Provider(
  (ref) => GetRolesUseCase(ref.watch(authRepositoryProvider)),
);
