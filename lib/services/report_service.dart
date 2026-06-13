import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/growth_report_model.dart';

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

  Future<LearningSummary> getLearningSummary({
    required int memberId,
    required String from,
    required String to,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/report/learning-summary',
    ).replace(queryParameters: {
      'memberId': memberId.toString(),
      'from': from,
      'to': to,
    });
    final headers = await _getHeaders();
    debugPrint('[ReportService] GET $url');
    final response = await http.get(url, headers: headers);
    debugPrint('[ReportService] getLearningSummary status: ${response.statusCode}');
    debugPrint('[ReportService] getLearningSummary response: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return LearningSummary.fromJson(json);
    }
    throw Exception('학습 요약 조회 실패: ${response.statusCode}');
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

  Future<bool> generateReport({required String weekStart}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports/generate');
    final headers = await _getHeaders();
    final body = jsonEncode({'week_start': weekStart});
    debugPrint('[ReportService] POST $url');
    debugPrint('[ReportService] body: $body');
    final response = await http.post(url, headers: headers, body: body);
    debugPrint('[ReportService] generateReport status: ${response.statusCode}');
    debugPrint('[ReportService] generateReport response: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode != 200) {
      throw Exception('리포트 생성 실패: ${response.statusCode} ${utf8.decode(response.bodyBytes)}');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return json['accepted'] as bool? ?? false;
  }
}
