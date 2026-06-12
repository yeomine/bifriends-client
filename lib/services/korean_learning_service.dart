import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/learning_model.dart';
import 'api_client.dart';

class KoreanLearningService {
  Future<RoadmapResponse> getRoadmap() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/korean/roadmap',
    );
    debugPrint('[Korean] GET $url');
    final response = await ApiClient.execute((h) => http.get(url, headers: h));
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
    final response = await ApiClient.execute((h) => http.get(url, headers: h));
    debugPrint('[Korean] content status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final cycles = json['cycles'] as List<dynamic>? ?? [];
      for (int i = 0; i < cycles.length; i++) {
        final c = cycles[i] as Map<String, dynamic>;
        final typeStr = c['type'] ?? c['cycle_type'];
        debugPrint('[Korean] cycle[$i] type="$typeStr"');
        debugPrint('[Korean] cycle[$i] keys=${c.keys.toList()}');
        if (typeStr == 'word_card') {
          final slides = c['slides'] as List?;
          final words = c['words'] as List?;
          debugPrint('[Korean] cycle[$i] slides=${slides?.length ?? 'null'} words=${words?.length ?? 'null'}');
          final items = slides ?? words ?? [];
          if (items.isNotEmpty) {
            debugPrint('[Korean] cycle[$i] item[0] keys=${(items.first as Map).keys.toList()}');
            debugPrint('[Korean] cycle[$i] item[0]=${items.first}');
          }
        }
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
    final response = await ApiClient.execute(
      (h) => http
          .post(url, headers: h, body: body)
          .timeout(const Duration(seconds: 15)),
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
    final response = await ApiClient.execute((h) => http.post(url, headers: h));
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
    final response = await ApiClient.execute((h) => http.post(url, headers: h));
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
