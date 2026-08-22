import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/location/domain/entities/region.dart';
import '../../domain/entities/senior_center.dart';
import '../../domain/repositories/welfare_center_repository.dart';
import '../datasources/welfare_center_remote_datasource.dart';

/// `search-welfare-centers` Edge Function을 호출한다(ONDAM 2.0 요구사항
/// 30) — 같은 예외→Failure 매핑 패턴을 `AnalysisRepositoryImpl`과 공유한다
/// (api.md). Edge Function이 `data_source_not_configured`를 반환하는 한
/// (사용자가 아직 data.go.kr 서비스키를 Supabase secret으로 등록하지 않은
/// 상태) `UnavailableFailure`로 정직하게 매핑되어, 이전
/// `UnavailableWelfareCenterRepositoryImpl`과 동일한 사용자 경험을 유지한다
/// — 배포/키 등록이 끝나는 즉시 실제 검색으로 자연스럽게 전환된다.
class WelfareCenterRepositoryImpl implements WelfareCenterRepository {
  const WelfareCenterRepositoryImpl(this._dataSource);

  final WelfareCenterRemoteDataSource _dataSource;

  @override
  Future<Result<List<SeniorCenter>>> search(Region region) async {
    try {
      final data = await _dataSource.search(region);
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      final rows = (data['results'] as List).cast<Map<String, dynamic>>();
      return Ok(rows.map(_toSeniorCenter).toList());
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

  SeniorCenter _toSeniorCenter(Map<String, dynamic> row) {
    return SeniorCenter(
      id: row['id'] as String,
      name: row['name'] as String,
      address: row['address'] as String,
      phoneNumber: row['phoneNumber'] as String?,
      // 서버는 사용자의 실시간 좌표를 받지 않으므로 거리를 계산할 수 없다
      // — 가짜 거리를 만들지 않고 항상 null로 둔다(요구사항 30 §7).
      distanceMeters: null,
    );
  }

  Failure _mapReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'invalid_region' => const ValidationFailure('내 지역 정보를 다시 확인해주세요.'),
      // 사용자가 아직 data.go.kr 서비스키를 등록하지 않은 상태 — 실제
      // "준비 중" 상태이지 서버 오류가 아니다(ai_provider_not_configured와
      // 동일한 이유).
      'data_source_not_configured' => const UnavailableFailure(
        '경로당 정보를 아직 제공하지 않아요.',
      ),
      'upstream_timeout' ||
      'upstream_error' ||
      'upstream_invalid_response' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }
}
