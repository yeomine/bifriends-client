import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// HTTP 요청 시 401이 오면 토큰을 자동으로 갱신하고 한 번 재시도합니다.
class ApiClient {
  static const _storage = FlutterSecureStorage();
  static final _auth = AuthService();

  static Future<Map<String, String>> getHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('로그인 토큰이 없습니다.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// [request]를 실행하고 401이면 토큰 갱신 후 한 번 재시도합니다.
  static Future<http.Response> execute(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final headers = await getHeaders();
    final response = await request(headers);

    if (response.statusCode != 401) return response;

    debugPrint('[ApiClient] 401 감지 — 토큰 갱신 시도');
    final newToken = await _auth.refreshAccessToken();
    if (newToken == null) {
      debugPrint('[ApiClient] 토큰 갱신 실패');
      return response;
    }

    debugPrint('[ApiClient] 토큰 갱신 성공 — 요청 재시도');
    final refreshedHeaders = await getHeaders();
    return request(refreshedHeaders);
  }
}
