import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/location/domain/entities/region.dart';

/// `search-welfare-centers`와 동일한 invoke-and-return-raw-map 패턴.
class BenefitServiceRemoteDataSource {
  const BenefitServiceRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> search({
    required int age,
    required String gender,
    required Region region,
  }) async {
    final response = await _client.functions.invoke(
      'search-benefit-services',
      body: {
        'age': age,
        'gender': gender,
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

  Future<Map<String, dynamic>> getDetail({
    required String id,
    required String source,
  }) async {
    final response = await _client.functions.invoke(
      'get-benefit-service-detail',
      body: {'id': id, 'source': source},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }
}
