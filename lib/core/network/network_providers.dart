import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

/// Shared DioClient instance — feature datasources depend on this instead of
/// constructing Dio directly.
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
