import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the `analyze-message` Edge Function — same invocation pattern as
/// `PinRemoteDataSource`/`ConnectionRemoteDataSource` (Supabase Functions
/// client attaches the caller's session token automatically, no manual
/// Authorization header, no separate Dio client — api.md's DioClient rule is
/// about this app's own backend, not Supabase Functions).
class MessageRiskRemoteDataSource {
  const MessageRiskRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> analyzeMessage(String message) async {
    final response = await _client.functions.invoke(
      'analyze-message',
      body: {'message': message},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }
}
