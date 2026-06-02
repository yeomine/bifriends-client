import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/learning_model.dart';

class MathLearningService {
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
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/learning/math/roadmap');
    final response = await http.get(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return RoadmapResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('로드맵 조회 실패: ${response.statusCode}');
  }

  Future<StepContentResponse> getStepContent(int stepId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/math/steps/$stepId/content',
    );
    final response = await http.get(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return StepContentResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('스텝 콘텐츠 조회 실패: ${response.statusCode}');
  }

  Future<ValidateResponse> validateAnswer({
    required int stepId,
    required int cycleNumber,
    required int questionIndex,
    required dynamic answer,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/math/steps/$stepId'
      '/cycles/$cycleNumber/questions/$questionIndex/validate',
    );
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'answer': answer}),
    );
    if (response.statusCode == 200) {
      return ValidateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('답안 검증 실패: ${response.statusCode}');
  }

  Future<CycleCompleteResponse> completeCycle({
    required int stepId,
    required int cycleNumber,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/math/steps/$stepId'
      '/cycles/$cycleNumber/complete',
    );
    final response = await http.post(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return CycleCompleteResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('사이클 완료 실패: ${response.statusCode}');
  }

  Future<StepCompleteResponse> completeStep(int stepId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/math/steps/$stepId/complete',
    );
    final response = await http.post(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return StepCompleteResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('스텝 완료 실패: ${response.statusCode}');
  }
}
