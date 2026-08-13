import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/camera_permission_status.dart';
import '../../domain/repositories/camera_repository.dart';
import '../datasources/camera_permission_datasource.dart';

class CameraRepositoryImpl implements CameraRepository {
  const CameraRepositoryImpl(this._dataSource);

  final CameraPermissionDataSource _dataSource;

  @override
  Future<Result<CameraPermissionStatus>> checkPermission() async {
    try {
      return Ok(await _dataSource.check());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<CameraPermissionStatus>> requestPermission() async {
    try {
      return Ok(await _dataSource.request());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }
}
