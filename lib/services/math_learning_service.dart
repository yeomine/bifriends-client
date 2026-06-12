import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/learning_model.dart';
import 'api_client.dart';

class MathLearningService {
  Future<RoadmapResponse> getRoadmap() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/learning/math/roadmap');
    final response = await ApiClient.execute((h) => http.get(url, headers: h));
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
    final response = await ApiClient.execute((h) => http.get(url, headers: h));
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
    final body = jsonEncode({'answer': answer});
    final response = await ApiClient.execute(
      (h) => http
          .post(url, headers: h, body: body)
          .timeout(const Duration(seconds: 15)),
    );
    if (response.statusCode == 200) {
      return ValidateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception(
      '답안 검증 실패: ${response.statusCode} ${utf8.decode(response.bodyBytes)}',
    );
  }

  Future<CycleCompleteResponse> completeCycle({
    required int stepId,
    required int cycleNumber,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/learning/math/steps/$stepId'
      '/cycles/$cycleNumber/complete',
    );
    final response = await ApiClient.execute((h) => http.post(url, headers: h));
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
    final response = await ApiClient.execute((h) => http.post(url, headers: h));
    if (response.statusCode == 200) {
      return StepCompleteResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('스텝 완료 실패: ${response.statusCode}');
  }
}
