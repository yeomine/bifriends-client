import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/growth_report_model.dart';
import '../models/guardian_mission_model.dart';

class ReportService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final String? accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null) throw Exception('로그인 토큰이 존재하지 않습니다.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<List<ReportSummary>> getReports() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports');
    final headers = await _getHeaders();
    debugPrint('[ReportService] GET $url');
    final response = await http.get(url, headers: headers);
    debugPrint('[ReportService] getReports status: ${response.statusCode}');
    debugPrint('[ReportService] getReports response: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (json['reports'] as List<dynamic>)
          .map((e) => ReportSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('리포트 목록 조회 실패: ${response.statusCode}');
  }

  Future<ReportDetail> getReportDetail(int reportId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports/$reportId');
    final headers = await _getHeaders();
    debugPrint('[ReportService] GET $url');
    final response = await http.get(url, headers: headers);
    debugPrint('[ReportService] getReportDetail status: ${response.statusCode}');
    debugPrint('[ReportService] getReportDetail response: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ReportDetail.fromJson(json);
    }
    throw Exception('리포트 상세 조회 실패: ${response.statusCode}');
  }

  Future<GuardianMission> getParentMission(int reportId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/reports/$reportId/parent-mission',
    );
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers);
    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return GuardianMission.fromJson(json);
    }
    throw Exception('보호자 미션 조회 실패: ${response.statusCode}');
  }

  Future<ChatSafetyDetail?> fetchWeeklySafetyReport({
    required int memberId,
    required String weekStart,
    required String weekEnd,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/weekly-safety-report');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'member_id': memberId,
      'week_start': weekStart,
      'week_end': weekEnd,
    });
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (json.containsKey('safety_signal')) {
        return ChatSafetyDetail(
          signal: ChatSafetyLevelExt.fromString(
            json['safety_signal'] as String? ?? '',
          ),
          score: (json['score'] as num?)?.toInt() ?? 0,
          reasonSummary: json['reason_summary'] as String? ?? '',
        );
      }
    }
    return null;
  }

  Future<bool> fetchWeeklyReport({
    required int memberId,
    required String weekStart,
    required String weekEnd,
    String sections = '',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/weekly-report');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'member_id': memberId,
      'week_start': weekStart,
      'week_end': weekEnd,
      'sections': sections,
    });
    debugPrint('[ReportService] POST $url');
    debugPrint('[ReportService] body: $body');
    final response = await http.post(url, headers: headers, body: body);
    debugPrint('[ReportService] status: ${response.statusCode}');
    debugPrint('[ReportService] response: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return json['received'] as bool? ?? false;
    }
    throw Exception('weekly-report 실패: ${response.statusCode} ${utf8.decode(response.bodyBytes)}');
  }
}
