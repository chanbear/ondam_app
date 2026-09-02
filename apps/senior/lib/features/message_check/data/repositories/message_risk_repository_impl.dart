import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/sms_message.dart';
import '../../domain/repositories/message_risk_repository.dart';
import '../datasources/message_risk_remote_datasource.dart';
import '../models/analysis_result_model.dart';

/// Calls `analyze-message` (Phase 8 AI risk analysis backend) via
/// [MessageRiskRemoteDataSource] — same Repository responsibility as
/// `ConnectionRepositoryImpl` (api.md): translate data-layer
/// exceptions/reason codes into domain [Failure]s.
class MessageRiskRepositoryImpl implements MessageRiskRepository {
  const MessageRiskRepositoryImpl(this._dataSource);

  final MessageRiskRemoteDataSource _dataSource;

  @override
  Future<Result<AnalysisResult>> analyzeMessage(
    SmsMessage message,
    String languageCode,
  ) async {
    try {
      final data = await _dataSource.analyzeMessage(message.body, languageCode);
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      return Ok(AnalysisResultModel.fromJson(data).toEntity());
    } on FunctionException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      return Err(_mapReason(reason));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> notifyGuardian({
    required String targetUserId,
    required String analysisResultId,
  }) async {
    try {
      final data = await _dataSource.notifyGuardian(
        targetUserId: targetUserId,
        analysisResultId: analysisResultId,
      );
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      return const Ok(null);
    } on FunctionException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      return Err(_mapReason(reason));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Failure _mapReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'invalid_message' ||
      'message_too_long' => const ValidationFailure('문자 내용을 다시 확인해주세요.'),
      // No AI provider configured in this environment — a real "not built
      // yet" state, distinct from a provider that tried and failed.
      'ai_provider_not_configured' => const UnavailableFailure(
        '분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.',
      ),
      'ai_provider_timeout' ||
      'ai_provider_error' ||
      'ai_response_invalid' ||
      'server_error' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }
}
