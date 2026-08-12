import 'package:dio/dio.dart';

import 'interceptors/error_interceptor.dart';

/// Single Dio instance shared by all feature data sources within one app. Do
/// not create Dio() ad hoc inside a feature — inject this via each app's own
/// `dioClientProvider` instead.
///
/// This package does not read `.env`/AppConfig itself — a `packages/*`
/// package must never depend on an `apps/*` package. Each app's own
/// `core/network/network_providers.dart` supplies [baseUrl] from its own
/// AppConfig when constructing this.
class DioClient {
  DioClient({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    dio.interceptors.add(ErrorInterceptor());
  }

  final Dio dio;
}
