import '../../../core/network/api_client.dart';

class AuthApi {
  Future<String> login({
    required String identifier,
    required String password,
  }) async {
    final response = await ApiClient.dio.post(
      '/auth/login',
      data: {
        'identifier': identifier,
        'password': password,
      },
    );

    final data = response.data['data'];

    if (data == null) {
      throw Exception('login data가 없습니다: ${response.data}');
    }

    final accessToken =
        data['accessToken'] ?? data['access_token'] ?? data['token'];

    if (accessToken == null) {
      throw Exception('accessToken이 없습니다: $data');
    }

    return accessToken.toString();
  }
}
