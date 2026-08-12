import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import 'interceptors/error_interceptor.dart';

/// Single Dio instance shared by all feature data sources. Do not create
/// Dio() ad hoc inside a feature — inject this via a Riverpod provider instead.
class DioClient {
  DioClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    dio.interceptors.add(ErrorInterceptor());
  }

  final Dio dio;
}
