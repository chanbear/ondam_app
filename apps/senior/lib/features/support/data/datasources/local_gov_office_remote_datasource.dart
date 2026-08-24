import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/location/domain/entities/region.dart';

/// Calls the `search-local-government-contact` Edge Function — same
/// invoke-and-return-raw-map pattern as `WelfareCenterRemoteDataSource`.
class LocalGovOfficeRemoteDataSource {
  const LocalGovOfficeRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> search(Region region) async {
    final response = await _client.functions.invoke(
      'search-local-government-contact',
      body: {
        'region': {
          'sido': region.sido,
          'sigungu': region.sigungu,
          'dong': region.dong,
        },
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
