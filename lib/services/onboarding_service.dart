import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class OnboardingService {
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

  Future<void> updateProfile({required String nickname, required int grade}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/onboarding/profile');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'nickname': nickname,
      'grade': grade,
    });

    final response = await http.patch(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('프로필 업데이트 실패: ${response.statusCode}');
    }
  }

  Future<void> updateInterests({required List<String> interests}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/onboarding/interests');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'interests': interests,
    });

    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('관심사 업데이트 실패: ${response.statusCode}');
    }
  }

  Future<void> selectGift({required String itemType}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/onboarding/gift');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'itemType': itemType,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('선물 선택 실패: ${response.statusCode}');
    }
  }
  Future<void> updatePermissions({
    required bool notificationEnabled,
    required bool microphoneEnabled,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/onboarding/permissions');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'notificationEnabled': notificationEnabled,
      'microphoneEnabled': microphoneEnabled,
    });

    final response = await http.patch(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('권한 업데이트 실패: ${response.statusCode}');
    }
  }

  Future<void> submitTerms({
    required bool termsAgreed,
    required bool privacyAgreed,
    required bool marketingAgreed,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/onboarding/terms');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'termsAgreed': termsAgreed,
      'privacyAgreed': privacyAgreed,
      'marketingAgreed': marketingAgreed,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('약관 동의 실패: ${response.statusCode}');
    }
  }

  Future<void> setupParentPassword({
    required String password,
    required String passwordConfirm,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/onboarding/parent-password');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'password': password,
      'passwordConfirm': passwordConfirm,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('부모님 비밀번호 설정 실패: ${response.statusCode}');
    }
  }

  Future<void> completeOnboarding() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/onboarding/complete');
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers, body: jsonEncode({}));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('온보딩 완료 처리 실패: ${response.statusCode}');
    }
  }
}
