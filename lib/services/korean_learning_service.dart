import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/learning_model.dart';

class KoreanLearningService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('로그인 토큰이 없습니다.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<RoadmapResponse> getRoadmap() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/korean/roadmap',
    );
    debugPrint('[Korean] GET $url');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[Korean] roadmap status: ${response.statusCode}');
    debugPrint('[Korean] roadmap body: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode == 200) {
      return RoadmapResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('국어 로드맵 조회 실패: ${response.statusCode}');
  }

  Future<StepContentResponse> getStepContent(int stepId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/korean/steps/$stepId/content',
    );
    debugPrint('[Korean] GET $url');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[Korean] content status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      // 사이클별로 쪼개서 출력 (truncation 방지)
      final cycles = json['cycles'] as List<dynamic>? ?? [];
      for (int i = 0; i < cycles.length; i++) {
        final c = cycles[i] as Map<String, dynamic>;
        debugPrint('[Korean] cycle[$i] type="${c['type'] ?? c['cycle_type']}"');
        debugPrint('[Korean] cycle[$i] keys=${c.keys.toList()}');
        final questions = c['questions'] as List?;
        if (questions != null && questions.isNotEmpty) {
          final q = questions.first as Map<String, dynamic>;
          debugPrint('[Korean] cycle[$i] Q[0] keys=${q.keys.toList()}');
          debugPrint('[Korean] cycle[$i] Q[0]=$q');
        }
      }
      return StepContentResponse.fromJson(json);
    }
    throw Exception('국어 스텝 콘텐츠 조회 실패: ${response.statusCode}');
  }

  Future<ValidateResponse> validateAnswer({
    required int stepId,
    required int cycleNumber,
    required int questionIndex,
    required String answer,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/korean/steps/$stepId'
      '/cycles/$cycleNumber/questions/$questionIndex/validate',
    );
    final body = jsonEncode({'answer': answer});
    debugPrint(
      '[Korean] stepId=$stepId, cycleNumber=$cycleNumber, questionIndex=$questionIndex',
    );
    debugPrint('[Korean] POST $url');
    debugPrint('[Korean] validate body: $body');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: body,
    );
    debugPrint('[Korean] validate status: ${response.statusCode}');
    debugPrint(
      '[Korean] validate response: ${utf8.decode(response.bodyBytes)}',
    );
    if (response.statusCode == 200) {
      return ValidateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('국어 답안 검증 실패: ${response.statusCode}');
  }

  Future<CycleCompleteResponse> completeCycle({
    required int stepId,
    required int cycleNumber,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/korean/steps/$stepId'
      '/cycles/$cycleNumber/complete',
    );
    debugPrint('[Korean] POST $url');
    final response = await http.post(url, headers: await _getHeaders());
    debugPrint('[Korean] completeCycle status: ${response.statusCode}');
    debugPrint(
      '[Korean] completeCycle response: ${utf8.decode(response.bodyBytes)}',
    );
    if (response.statusCode == 200) {
      return CycleCompleteResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('국어 사이클 완료 실패: ${response.statusCode}');
  }

  Future<StepCompleteResponse> completeStep(int stepId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/korean/steps/$stepId/complete',
    );
    debugPrint('[Korean] POST $url');
    final response = await http.post(url, headers: await _getHeaders());
    debugPrint('[Korean] completeStep status: ${response.statusCode}');
    debugPrint(
      '[Korean] completeStep response: ${utf8.decode(response.bodyBytes)}',
    );
    if (response.statusCode == 200) {
      return StepCompleteResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('국어 스텝 완료 실패: ${response.statusCode}');
  }
}
