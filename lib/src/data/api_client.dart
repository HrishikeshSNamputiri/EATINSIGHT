import 'package:dio/dio.dart';
import '../core/env.dart';

class ApiClient {
  late final Dio _dio;
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.baseApiUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept-Language': Env.defaultLocale},
            ));

  Dio get raw => _dio;
}
