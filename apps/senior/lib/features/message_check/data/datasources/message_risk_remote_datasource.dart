import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the `analyze-message` Edge Function — same invocation pattern as
/// `PinRemoteDataSource`/`ConnectionRemoteDataSource` (Supabase Functions
/// client attaches the caller's session token automatically, no manual
/// Authorization header, no separate Dio client — api.md's DioClient rule is
/// about this app's own backend, not Supabase Functions).
class MessageRiskRemoteDataSource {
  const MessageRiskRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> analyzeMessage(
    String message,
    String languageCode,
  ) async {
    final response = await _client.functions.invoke(
      'analyze-message',
      body: {'message': message, 'language': languageCode},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }

  /// `send-notification` Edge Function 호출 — `elder_id`/`analysis_result_id`를
  /// payload에 실어 보내면 Guardian 앱의 푸시 탭 딥링크가 그 값을 그대로
  /// 읽는다(`send-notification/index.ts`의 `fcmData` 처리부 참고).
  Future<Map<String, dynamic>> notifyGuardian({
    required String targetUserId,
    required String analysisResultId,
  }) async {
    final elderId = _client.auth.currentUser?.id;
    if (elderId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    final response = await _client.functions.invoke(
      'send-notification',
      body: {
        'targetUserId': targetUserId,
        'type': 'message_risk_alert',
        'payload': {
          'title': '위험 문자 알림',
          'body': '어르신이 확인한 문자에서 위험이 감지됐어요.',
          'elder_id': elderId,
          'analysis_result_id': analysisResultId,
        },
        'sentVia': 'push',
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }
}
