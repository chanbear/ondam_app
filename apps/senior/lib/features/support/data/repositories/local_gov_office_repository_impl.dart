import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/location/domain/entities/region.dart';
import '../../domain/entities/local_gov_office.dart';
import '../../domain/repositories/local_gov_office_repository.dart';
import '../datasources/local_gov_office_remote_datasource.dart';

/// `search-local-government-contact` Edge Function을 호출한다 — 같은
/// 예외→Failure 매핑 패턴을 `WelfareCenterRepositoryImpl`과 공유한다
/// (api.md). `result`가 null이면 일치하는 기관을 찾지 못한 것이지 오류가
/// 아니므로 `Ok(null)`로 정직하게 반환한다.
class LocalGovOfficeRepositoryImpl implements LocalGovOfficeRepository {
  const LocalGovOfficeRepositoryImpl(this._dataSource);

  final LocalGovOfficeRemoteDataSource _dataSource;

  @override
  Future<Result<LocalGovOffice?>> search(Region region) async {
    try {
      final data = await _dataSource.search(region);
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      final result = data['result'];
      if (result == null) return const Ok(null);
      return Ok(_toLocalGovOffice(result as Map<String, dynamic>));
    } on FunctionException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      return Err(_mapReason(reason));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  LocalGovOffice _toLocalGovOffice(Map<String, dynamic> row) {
    return LocalGovOffice(
      address: row['address'] as String,
      postalCode: row['postalCode'] as String?,
      // 데이터 소스에 전화번호 컬럼이 없다(LocalGovOffice 주석 참고) —
      // 서버가 항상 null을 보내지만, 필드 자체는 미래 데이터 소스 교체를
      // 대비해 그대로 통과시킨다.
      phoneNumber: row['phoneNumber'] as String?,
    );
  }

  Failure _mapReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'invalid_region' => const ValidationFailure('내 지역 정보를 다시 확인해주세요.'),
      // 사용자가 아직 data.go.kr 서비스키를 등록하지 않은 상태 —
      // welfare_center와 동일한 이유로 실제 "준비 중" 상태다.
      'data_source_not_configured' => const UnavailableFailure(
        '관할 행정복지센터 연락처를 아직 제공하지 않아요.',
      ),
      'upstream_timeout' ||
      'upstream_error' ||
      'upstream_invalid_response' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }
}
