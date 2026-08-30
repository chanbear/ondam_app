import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/captured_photo.dart';

const _documentPhotosBucket = 'document-photos';

/// Uploads a captured photo to the `document-photos` Storage bucket, then
/// calls the `analyze-document` Edge Function with the resulting path.
/// Two-step by design (technical-decisions.md §2 item 7): the Edge Function
/// only ever receives a storage path, never the raw image bytes over the
/// function-invoke payload, and the caller's own JWT (not a service key) is
/// what authorizes the upload via the bucket's owner-only RLS policy.
class AnalysisRemoteDataSource {
  const AnalysisRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> analyzeDocument(CapturedPhoto photo) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }

    final bytes = await XFile(photo.localPath).readAsBytes();
    final storagePath =
        '$userId/${photo.capturedAt.microsecondsSinceEpoch}.jpg';

    await _client.storage
        .from(_documentPhotosBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    final response = await _client.functions.invoke(
      'analyze-document',
      body: {'storagePath': storagePath},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }
}
