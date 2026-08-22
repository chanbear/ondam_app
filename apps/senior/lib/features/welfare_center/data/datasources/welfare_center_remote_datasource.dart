import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/location/domain/entities/region.dart';

/// Calls the `search-welfare-centers` Edge Function — same
/// invoke-and-return-raw-map pattern as `AnalysisRemoteDataSource`. Only the
/// already-saved 시/도·시/군/구 text is sent, never raw GPS coordinates
/// (ONDAM 2.0 요구사항 30 §9 위치 개인정보 원칙).
class WelfareCenterRemoteDataSource {
  const WelfareCenterRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> search(Region region) async {
    final response = await _client.functions.invoke(
      'search-welfare-centers',
      body: {
        'region': {'sido': region.sido, 'sigungu': region.sigungu},
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
