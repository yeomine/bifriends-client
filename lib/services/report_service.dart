import 'dart:convert';
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
    final response = await http.get(url, headers: headers);
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
    final response = await http.get(url, headers: headers);
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
}
