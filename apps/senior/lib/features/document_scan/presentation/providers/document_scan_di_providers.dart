import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/camera_permission_datasource.dart';
import '../../data/repositories/analysis_repository_impl.dart';
import '../../data/repositories/camera_repository_impl.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../domain/usecases/analyze_document_usecase.dart';
import '../../domain/usecases/check_camera_permission_usecase.dart';
import '../../domain/usecases/request_camera_permission_usecase.dart';

final cameraPermissionDataSourceProvider = Provider(
  (ref) => CameraPermissionDataSource(),
);

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepositoryImpl(ref.watch(cameraPermissionDataSourceProvider));
});

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return const AnalysisRepositoryImpl();
});

final checkCameraPermissionUseCaseProvider = Provider(
  (ref) => CheckCameraPermissionUseCase(ref.watch(cameraRepositoryProvider)),
);

final requestCameraPermissionUseCaseProvider = Provider(
  (ref) => RequestCameraPermissionUseCase(ref.watch(cameraRepositoryProvider)),
);

final analyzeDocumentUseCaseProvider = Provider(
  (ref) => AnalyzeDocumentUseCase(ref.watch(analysisRepositoryProvider)),
);
