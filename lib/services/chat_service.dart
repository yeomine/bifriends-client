import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/chat_model.dart';

class ChatService {
  static String generateSessionId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final String? accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null) throw Exception('로그인 토큰이 없습니다.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<ChatResponse> sendMessage({
    required String sessionId,
    required String message,
    required String nickname,
    required int grade,
    required List<String> interests,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/messages');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'sessionId': sessionId,
        'message': message,
        'nickname': nickname,
        'grade': grade,
        'interests': interests,
      }),
    );

    debugPrint('[ChatService] sendMessage status: ${response.statusCode}');
    debugPrint(
      '[ChatService] sendMessage body: ${utf8.decode(response.bodyBytes)}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final chatResponse = ChatResponse.fromJson(json);
        debugPrint(
          '[ChatService] reply: "${chatResponse.reply}", cta: ${chatResponse.cta?.type}',
        );
        return chatResponse;
      } catch (e) {
        debugPrint('[ChatService] 파싱 오류: $e');
        rethrow;
      }
    }
    throw Exception('메시지 전송 실패: ${response.statusCode}');
  }

  Future<List<ChatSession>> getMySessions() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/sessions');
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[ChatService] getMySessions status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (data['sessions'] as List<dynamic>)
          .map((s) => ChatSession.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    throw Exception('세션 목록 로드 실패: ${response.statusCode}');
  }

  Future<void> deleteSession(String sessionId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/chat/sessions/$sessionId',
    );
    final response = await http.delete(url, headers: await _getHeaders());
    debugPrint('[ChatService] deleteSession status: ${response.statusCode}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('세션 삭제 실패: ${response.statusCode}');
    }
  }

  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/chat/my/sessions/$sessionId/messages',
    );
    final response = await http.get(url, headers: await _getHeaders());
    debugPrint('[ChatService] getSessionMessages status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (data['messages'] as List<dynamic>)
          .map(
            (m) => ChatMessage(
              id: (m['id'] as num).toString(),
              content: m['content'] as String,
              isUser: (m['role'] as String) == 'USER',
              timestamp: DateTime.parse(m['createdAt'] as String),
            ),
          )
          .toList();
    }
    throw Exception('세션 메시지 로드 실패: ${response.statusCode}');
  }
}
