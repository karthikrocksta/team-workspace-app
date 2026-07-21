import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Thin wrapper around [Dio] so that base URL, timeouts, and interceptors
/// are configured in a single place and injected via GetIt.
class DioClient {
  final Dio dio;

  DioClient(this.dio) {
    dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          // In production this would route to a proper logger (e.g. Sentry).
          assert(() {
            // ignore: avoid_print
            print(obj);
            return true;
          }());
        },
      ),
    );
  }
}
