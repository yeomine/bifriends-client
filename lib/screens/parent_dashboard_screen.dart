import 'package:flutter/material.dart';
import '../models/growth_report_model.dart';
import '../services/report_service.dart';
import '../services/member_service.dart';
import '../theme/app_colors.dart';
import '../widgets/guardian_mission_sheet.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  static const _allDays = LearningPattern.allDayLabels;

  final _reportService = ReportService();
  final _memberService = MemberService();

  List<ReportSummary> _summaries = [];
  ReportDetail? _detail;
  String _childName = '';
  int _selectedIndex = 0;

  bool _isListLoading = true;
  bool _isDetailLoading = false;
  bool _isMissionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchChildName(), _fetchReportList()]);
  }

  Future<void> _fetchChildName() async {
    try {
      final member = await _memberService.getMe();
      if (mounted) setState(() => _childName = member.nickname ?? member.name);
    } catch (_) {}
  }

  Future<void> _fetchReportList() async {
    try {
      final summaries = await _reportService.getReports();
      if (mounted) {
        setState(() {
          _summaries = summaries;
          _isListLoading = false;
        });
        if (summaries.isNotEmpty) {
          await _fetchDetail(summaries.first.reportId);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isListLoading = false);
    }
  }

  Future<void> _fetchDetail(int reportId) async {
    setState(() => _isDetailLoading = true);
    try {
      final detail = await _reportService.getReportDetail(reportId);
      if (mounted) setState(() => _detail = detail);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  void _onSelectReport(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _fetchDetail(_summaries[index].reportId);
  }

  Future<void> _onMissionTap() async {
    if (_summaries.isEmpty || _isMissionLoading) return;

    // 이미 detail에 미션이 포함된 경우 바로 시트 표시
    if (_detail?.parentMission != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => GuardianMissionSheet(mission: _detail!.parentMission!),
      );
      return;
    }

    setState(() => _isMissionLoading = true);
    try {
      final reportId = _summaries[_selectedIndex].reportId;
      final mission = await _reportService.getParentMission(reportId);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => GuardianMissionSheet(mission: mission),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미션을 불러오는 데 실패했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMissionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: _isListLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _summaries.isEmpty
          ? _buildEmptyState()
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeekSelector(),
                    Expanded(
                      child: _isDetailLoading || _detail == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSummaryCard(_detail!),
                                  if (_detail!.growth.parentTip != null) ...[
                                    const SizedBox(height: 24),
                                    _buildParentTipCard(_detail!.growth.parentTip!),
                                  ],
                                  const SizedBox(height: 24),
                                  _buildLearningPatternCard(_detail!),
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
                                  ..._detail!.learningStatus.all.map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _buildSubjectCard(s),
                                    ),
                                  ),
                                  if (_detail!.chatSafety != null)
                                    _buildChatSafetyCard(_detail!.chatSafety!),
                                  if (_detail!.keywords.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildKeywordsCard(_detail!.keywords),
                                  ],
                                  const SizedBox(height: 16),
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
                  child: _buildMissionButton(),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
          if (_childName.isNotEmpty)
            Text(
              _childName,
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
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: _summaries.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _buildReportPill(_summaries[i].weekRange, i),
      ),
    );
  }

  Widget _buildReportPill(String weekRange, int index) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onSelectReport(index),
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

  Widget _buildSummaryCard(ReportDetail detail) {
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
            detail.growth.summary,
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

  Widget _buildParentTipCard(String tip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text(
                '부모 팁',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tip,
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

  Widget _buildLearningPatternCard(ReportDetail detail) {
    final pattern = detail.learningPattern;
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
                    value: pattern.learningDays.isEmpty
                        ? '-'
                        : pattern.learningDays
                            .map((d) => _allDays[d - 1])
                            .join(', '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.show_chart,
                    label: '완료한 학습',
                    value: '${pattern.completedTodoCount}',
                    valueLarge: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_allDays.length, (i) {
              final isActive = pattern.isDayActive(i + 1);
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
                    _allDays[i],
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
            }),
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

  Widget _buildSubjectCard(SubjectSummary subject) {
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
              Icon(subject.icon, color: subject.color, size: 22),
              const SizedBox(width: 8),
              Text(
                subject.displayName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subject.summary,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSafetyCard(ChatSafetyDetail safety) {
    final level = safety.signal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: level.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: level.color, size: 20),
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
                level.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: level.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${safety.score}점',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: level.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            safety.reasonSummary.isNotEmpty
                ? safety.reasonSummary
                : level.defaultDescription,
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

  Widget _buildKeywordsCard(List<String> keywords) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.label_outline, color: AppColors.textSub, size: 18),
              SizedBox(width: 6),
              Text(
                '이번 주 주요 키워드',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.map((kw) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  kw,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionButton() {
    final hasMission = _detail?.parentMission != null ||
        (_summaries.isNotEmpty && _summaries[_selectedIndex].hasMission);

    return ElevatedButton(
      onPressed: _isMissionLoading ? null : _onMissionTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primaryDisabled,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
      child: _isMissionLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, size: 20),
                const SizedBox(width: 10),
                Text(
                  hasMission ? '이번주 보호자 미션 보기' : '이번주 보호자 미션 받기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.auto_awesome, size: 16),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 60,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: 20),
          const Text(
            '아직 리포트가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '학습을 진행하면 주간 리포트가 생성돼요.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}
