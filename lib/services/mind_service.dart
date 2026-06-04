import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/mind_model.dart';
import 'auth_service.dart';

class MindService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final String? accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null) {
      throw Exception('로그인 토큰이 존재하지 않습니다. 다시 로그인해주세요.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  /// 401 응답 시 토큰을 갱신하고 [call]을 재시도합니다.
  Future<http.Response> _withTokenRefresh(
    Future<http.Response> Function(Map<String, String> headers) call,
  ) async {
    final headers = await _getHeaders();
    final response = await call(headers);

    if (response.statusCode != 401) return response;

    // 토큰 갱신 시도
    final newToken = await AuthService().refreshAccessToken();
    if (newToken == null) {
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    }

    final refreshedHeaders = await _getHeaders();
    return call(refreshedHeaders);
  }

  Future<MindScenario> generateScenario(String emotion) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/mind/scenario');
    debugPrint('[MindService] generateScenario 요청 → emotion: $emotion, url: $url');

    late http.Response response;
    try {
      response = await _withTokenRefresh(
        (headers) => http.post(
          url,
          headers: headers,
          body: jsonEncode({'emotion': emotion}),
        ),
      );
    } catch (e) {
      debugPrint('[MindService] generateScenario 네트워크 오류: $e');
      rethrow;
    }

    debugPrint('[MindService] generateScenario 응답 status: ${response.statusCode}');
    debugPrint('[MindService] generateScenario 응답 body: ${utf8.decode(response.bodyBytes)}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final scenario = MindScenario.fromJson(json);
        debugPrint('[MindService] generateScenario 파싱 성공 → setId: ${scenario.setId}');
        return scenario;
      } catch (e) {
        debugPrint('[MindService] generateScenario 파싱 오류: $e');
        rethrow;
      }
    }
    throw Exception('시나리오 생성 실패: ${response.statusCode}');
  }

  Future<int> saveSession(MindScenario scenario) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/mind/sessions');
    final response = await _withTokenRefresh(
      (headers) => http.post(
        url,
        headers: headers,
        body: jsonEncode(scenario.toJson()),
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return json['rewardAmount'] as int? ?? 0;
    }
    throw Exception('세션 저장 실패: ${response.statusCode}');
  }

  Future<List<MindSessionSummary>> getSessions() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/mind/sessions');
    final response = await _withTokenRefresh(
      (headers) => http.get(url, headers: headers),
    );

    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (json['sessions'] as List<dynamic>)
          .map((e) => MindSessionSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('세션 목록 조회 실패: ${response.statusCode}');
  }

  Future<MindScenario> getSession(String sessionId) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mind/sessions/$sessionId');
    final response = await _withTokenRefresh(
      (headers) => http.get(url, headers: headers),
    );

    if (response.statusCode == 200) {
      return MindScenario.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('세션 상세 조회 실패: ${response.statusCode}');
  }
}
