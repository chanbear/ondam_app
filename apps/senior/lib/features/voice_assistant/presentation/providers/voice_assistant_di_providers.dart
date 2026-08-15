import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mic_permission_datasource.dart';
import '../../data/repositories/mic_repository_impl.dart';
import '../../domain/repositories/mic_repository.dart';
import '../../domain/usecases/check_mic_permission_usecase.dart';
import '../../domain/usecases/classify_voice_intent_usecase.dart';
import '../../domain/usecases/request_mic_permission_usecase.dart';

final micPermissionDataSourceProvider = Provider(
  (ref) => MicPermissionDataSource(),
);

final micRepositoryProvider = Provider<MicRepository>((ref) {
  return MicRepositoryImpl(ref.watch(micPermissionDataSourceProvider));
});

final checkMicPermissionUseCaseProvider = Provider(
  (ref) => CheckMicPermissionUseCase(ref.watch(micRepositoryProvider)),
);

final requestMicPermissionUseCaseProvider = Provider(
  (ref) => RequestMicPermissionUseCase(ref.watch(micRepositoryProvider)),
);

final classifyVoiceIntentUseCaseProvider = Provider(
  (ref) => const ClassifyVoiceIntentUseCase(),
);
