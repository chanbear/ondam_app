import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/mic_permission_status.dart';
import '../../domain/repositories/mic_repository.dart';
import '../datasources/mic_permission_datasource.dart';

class MicRepositoryImpl implements MicRepository {
  const MicRepositoryImpl(this._dataSource);

  final MicPermissionDataSource _dataSource;

  @override
  Future<Result<MicPermissionStatus>> checkPermission() async {
    try {
      return Ok(await _dataSource.check());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<MicPermissionStatus>> requestPermission() async {
    try {
      return Ok(await _dataSource.request());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }
}
