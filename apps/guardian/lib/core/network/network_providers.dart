import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_network/ondam_network.dart';

import '../../app/config/app_config.dart';

/// Shared DioClient instance — feature datasources depend on this instead of
/// constructing Dio directly. `ondam_network`'s DioClient does not know
/// about AppConfig (packages/ must not depend on apps/), so this app-level
/// provider is what actually wires baseUrl in.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(baseUrl: AppConfig.apiBaseUrl);
});
