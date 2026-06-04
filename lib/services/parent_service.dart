import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ParentService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final String? accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null) throw Exception('로그인 토큰이 존재하지 않습니다.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<bool> verifyPassword(String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/parent/verify');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return json['verified'] as bool? ?? false;
    }
    throw Exception('비밀번호 확인 실패: ${response.statusCode}');
  }

  Future<void> resetPassword(String newPassword, String newPasswordConfirm) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/parent/reset-password');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'newPassword': newPassword,
        'newPasswordConfirm': newPasswordConfirm,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('비밀번호 초기화 실패: ${response.statusCode}');
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String newPasswordConfirm,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/parent/password');
    final headers = await _getHeaders();
    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'newPasswordConfirm': newPasswordConfirm,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('비밀번호 변경 실패: ${response.statusCode}');
    }
  }
}
