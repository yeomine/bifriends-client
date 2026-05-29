import 'package:flutter/material.dart';
import '../models/growth_report_model.dart';
import '../theme/app_colors.dart';
import '../widgets/guardian_mission_sheet.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  static const _allDays = ['월', '화', '수', '목', '금', '토', '일'];

  // TODO: BE 연동 시 API 응답으로 교체
  final List<GrowthReport> _reports = GrowthReport.mockHistory();
  bool _hasLatestReport = false;
  int _selectedIndex = 0;

  GrowthReport get _currentReport => _reports[_selectedIndex];

  void _generateLatestReport() {
    // TODO: BE 연동 시 API 호출로 교체
    setState(() {
      _reports.insert(0, GrowthReport.mockLatest());
      _hasLatestReport = true;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = _currentReport;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, report.childName),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeekSelector(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(report),
                      const SizedBox(height: 24),
                      _buildLearningPatternCard(report),
                      const SizedBox(height: 24),
                      const Text(
                        '학습 현황',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...report.subjects.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSubjectCard(s),
                        ),
                      ),
                      if (report.chatSafetySignal != null) ...[
                        _buildChatSafetyCard(report.chatSafetySignal!),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: _buildMissionButton(context),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String childName) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.textMain,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          const Text(
            '성장 리포트',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          Text(
            childName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.person_2_outlined,
            color: AppColors.textMain,
            size: 24,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildWeekSelector() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        children: [
          if (!_hasLatestReport) ...[
            _buildGenerateButton(),
            const SizedBox(width: 8),
          ],
          ..._reports.asMap().entries.map((entry) {
            final isLast = entry.key == _reports.length - 1;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: _buildReportPill(entry.value.weekRange, entry.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return OutlinedButton.icon(
      onPressed: _generateLatestReport,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('최신 리포트 생성'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMain,
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildReportPill(String weekRange, int index) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textMain : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.textMain : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Text(
          weekRange,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textMain,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(GrowthReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                '이번 주의 성장 요약',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            report.summary,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPatternCard(GrowthReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textMain,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 학습 패턴',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.calendar_today_outlined,
                    label: '학습 요일',
                    value: report.pattern.studyDays.join(', '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.show_chart,
                    label: '총 학습 횟수',
                    value: '${report.pattern.totalStudyCount}',
                    valueLarge: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _allDays.map((day) {
              final isActive = report.pattern.studyDays.contains(day);
              return Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    bool valueLarge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4DB6AC), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: valueLarge ? 28 : 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(SubjectReport subject) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(subject.type.icon, color: subject.type.color, size: 22),
              const SizedBox(width: 8),
              Text(
                subject.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPointBox(
            label: '잘한 점',
            content: subject.goodPoint,
            isGood: true,
          ),
          if (subject.hardPoint != null) ...[
            const SizedBox(height: 10),
            _buildPointBox(
              label: '어려웠던 점',
              content: subject.hardPoint!,
              isGood: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointBox({
    required String label,
    required String content,
    required bool isGood,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isGood ? const Color(0xFF5B9BD5) : AppColors.textSub,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSafetyCard(ChatSafetySignal signal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: signal.level.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: signal.level.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: signal.level.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '챗 안전 신호: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                signal.level.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: signal.level.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            signal.description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const GuardianMissionSheet(),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 20),
          SizedBox(width: 10),
          Text(
            '이번주 보호자 미션 받기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 10),
          Icon(Icons.auto_awesome, size: 16),
        ],
      ),
    );
  }
}

