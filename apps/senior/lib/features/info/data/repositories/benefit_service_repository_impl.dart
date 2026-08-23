import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../../domain/entities/benefit_service.dart';
import '../../domain/entities/benefit_service_detail.dart';
import '../../domain/repositories/benefit_service_repository.dart';
import '../datasources/benefit_service_remote_datasource.dart';

/// `WelfareCenterRepositoryImpl`과 동일한 예외→Failure 매핑 패턴.
class BenefitServiceRepositoryImpl implements BenefitServiceRepository {
  const BenefitServiceRepositoryImpl(this._dataSource);

  final BenefitServiceRemoteDataSource _dataSource;

  @override
  Future<Result<List<BenefitService>>> search(
    Demographics demographics,
    Region region,
  ) async {
    try {
      final data = await _dataSource.search(
        age: demographics.age!,
        gender: demographics.gender!.value,
        region: region,
      );
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      final rows = (data['results'] as List).cast<Map<String, dynamic>>();
      return Ok(rows.map(_toBenefitService).toList());
    } on FunctionException catch (e) {
      return Err(_mapReason(_reasonFrom(e)));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<BenefitServiceDetail>> getDetail(
    String id,
    BenefitServiceSource source,
  ) async {
    try {
      final data = await _dataSource.getDetail(id: id, source: source.value);
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      return Ok(
        _toBenefitServiceDetail(data['result'] as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      return Err(_mapReason(_reasonFrom(e)));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  String? _reasonFrom(FunctionException e) {
    final details = e.details;
    return details is Map ? details['reason'] as String? : null;
  }

  BenefitService _toBenefitService(Map<String, dynamic> row) {
    return BenefitService(
      id: row['id'] as String,
      source:
          BenefitServiceSource.fromValue(row['source'] as String?) ??
          BenefitServiceSource.central,
      title: row['title'] as String,
      summary: row['summary'] as String,
    );
  }

  BenefitServiceDetail _toBenefitServiceDetail(Map<String, dynamic> row) {
    return BenefitServiceDetail(
      id: row['id'] as String,
      title: row['title'] as String,
      summary: row['summary'] as String,
      supportTarget: row['supportTarget'] as String?,
      applyMethod: row['applyMethod'] as String?,
      contact: row['contact'] as String?,
      externalUrl: row['externalUrl'] as String?,
    );
  }

  Failure _mapReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'invalid_request' => const ValidationFailure('요청 정보를 다시 확인해주세요.'),
      'not_found' => const ValidationFailure('더 이상 제공되지 않는 혜택 정보예요.'),
      'data_source_not_configured' => const UnavailableFailure(
        '맞춤 혜택 정보를 아직 제공하지 않아요.',
      ),
      'upstream_timeout' ||
      'upstream_error' ||
      'upstream_invalid_response' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }
}
