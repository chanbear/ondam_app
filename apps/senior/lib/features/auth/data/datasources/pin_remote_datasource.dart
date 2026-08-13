import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the PIN-related Edge Functions (`set-pin`/`verify-pin`/`reset-pin`/
/// `has-pin`/`delete-account`) via the Supabase SDK's Functions client,
/// which attaches the current session's access token automatically — no
/// manual Authorization header, no separate Dio client/base URL (these are
/// Supabase Functions, not this app's general API — see api.md's DioClient
/// rule, which is about the app's own backend, not this).
///
/// `set-pin`/`verify-pin`/`reset-pin` are the ONLY code paths in this app
/// that ever transmit a PIN — never persisted locally in any form.
class PinRemoteDataSource {
  const PinRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> setPin(String pin) =>
      _invoke('set-pin', {'pin': pin});

  Future<Map<String, dynamic>> verifyPin(String pin) =>
      _invoke('verify-pin', {'pin': pin});

  Future<Map<String, dynamic>> resetPin(String pin) =>
      _invoke('reset-pin', {'pin': pin});

  Future<Map<String, dynamic>> hasPin() => _invoke('has-pin', const {});

  Future<Map<String, dynamic>> deleteAccount() =>
      _invoke('delete-account', const {});

  Future<Map<String, dynamic>> _invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(functionName, body: body);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }
}
