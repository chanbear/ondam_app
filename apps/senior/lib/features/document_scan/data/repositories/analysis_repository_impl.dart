import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/captured_photo.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../datasources/analysis_remote_datasource.dart';
import '../models/analysis_result_model.dart';

/// Calls `analyze-document` (Storage upload + Edge Function, per
/// technical-decisions.md §1-7/§1-8) via [AnalysisRemoteDataSource] — same
/// Repository responsibility as `MessageRiskRepositoryImpl` (api.md):
/// translate data-layer exceptions/reason codes into domain [Failure]s.
class AnalysisRepositoryImpl implements AnalysisRepository {
  const AnalysisRepositoryImpl(this._dataSource);

  final AnalysisRemoteDataSource _dataSource;

  @override
  Future<Result<AnalysisResult>> analyzeDocument(CapturedPhoto photo) async {
    try {
      final data = await _dataSource.analyzeDocument(photo);
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      return Ok(AnalysisResultModel.fromJson(data).toEntity());
    } on FunctionException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      return Err(_mapReason(reason));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } on StorageException catch (_) {
      return const Err(ServerFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Failure _mapReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'invalid_storage_path' ||
      'image_too_large' => const ValidationFailure('사진을 다시 확인해주세요.'),
      // No AI provider configured in this environment — a real "not built
      // yet" state, distinct from a provider that tried and failed.
      'ai_provider_not_configured' => const UnavailableFailure(
        '분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.',
      ),
      'ai_provider_timeout' ||
      'ai_provider_error' ||
      'ai_response_invalid' ||
      'storage_download_failed' ||
      'server_error' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }
}
