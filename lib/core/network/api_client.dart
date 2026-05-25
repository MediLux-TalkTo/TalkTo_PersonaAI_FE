import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://talkto-personaai-be.onrender.com/api/v1',
  );
}

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  )
    ..interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,

        // release 모드에서는 로그 끄기
        logPrint: (obj) {
          if (kDebugMode) {
            debugPrint(obj.toString());
          }
        },
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          debugPrint('API ERROR: ${e.response?.statusCode}');
          debugPrint('API ERROR BODY: ${e.response?.data}');

          // TODO:
          // 401 시 refresh token 처리 가능

          handler.next(e);
        },
      ),
    );

  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
