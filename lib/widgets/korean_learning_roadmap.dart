import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/learning_model.dart';
import '../models/member_model.dart';
import '../screens/learning_activity_screen.dart';
import '../services/korean_learning_service.dart';
import '../services/member_service.dart';
import '../widgets/learning_roadmap.dart'
    show LevelData, LevelStatus, RoadmapPainter;
import '../theme/app_colors.dart';

const int _cyclesPerLevel = 5;

class KoreanLearningRoadmap extends StatefulWidget {
  final VoidCallback? onAnyStepCompleted;
  const KoreanLearningRoadmap({super.key, this.onAnyStepCompleted});

  @override
  State<KoreanLearningRoadmap> createState() => _KoreanLearningRoadmapState();
}

class _KoreanLearningRoadmapState extends State<KoreanLearningRoadmap> {
  List<StepSummaryResponse> _steps = [];
  bool _loaded = false;
  int _grade = 3;
  String _nickname = '친구';
  final ScrollController _scrollController = ScrollController();
  final KoreanLearningService _service = KoreanLearningService();
  final MemberService _memberService = MemberService();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final results = await Future.wait([
      _service.getRoadmap().then<List<StepSummaryResponse>>((r) => r.steps).catchError((_) => <StepSummaryResponse>[]),
      _memberService.getMe().then<Member>((m) => m).catchError((_) => Member(email: '', name: '', notificationEnabled: false, microphoneEnabled: false, onboardingCompleted: false)),
    ]);
    if (!mounted) return;
    setState(() {
      _steps = results[0] as List<StepSummaryResponse>;
      final member = results[1] as Member;
      _grade = member.grade ?? 3;
      _nickname = member.nickname ?? '친구';
      _loaded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToCurrentLevel(),
    );
  }

  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;
    const nodeHeight = 210.0;
    const topPadding = 90.0;
    final currentIndex = _levelDatas.indexWhere(
      (l) => l.status == LevelStatus.current,
    );
    if (currentIndex <= 1) return;
    final targetY = (topPadding + currentIndex * nodeHeight - 80.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetY,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  LevelStatus _levelStatusFrom(StepStatus status) {
    switch (status) {
      case StepStatus.COMPLETED:
        return LevelStatus.completed;
      case StepStatus.IN_PROGRESS:
      case StepStatus.AVAILABLE:
        return LevelStatus.current;
      case StepStatus.LOCKED:
        return LevelStatus.locked;
    }
  }

  List<LevelData> get _levelDatas => _steps
      .map(
        (s) => LevelData(
          level: s.stepNumber,
          stepId: s.stepId,
          title: 'STEP ${s.stepNumber}',
          description: s.stepTitle,
          subtitle: s.concept,
          status: _levelStatusFrom(s.status),
          completedCycles: s.completedCycles,
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final levelDatas = _levelDatas;

    if (levelDatas.isEmpty) {
      return const Center(
        child: Text(
          '로드맵을 불러올 수 없어요 😢\n잠시 후 다시 시도해줘!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSub,
            height: 1.6,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final sw = constraints.maxWidth;
        const nodeHeight = 210.0;
        const circleAreaSize = 150.0;
        const topPadding = 90.0;
        const gap = 14.0;
        final cardWidth = (sw * 0.7 - 105).clamp(110.0, 162.0);
        final totalHeight = levelDatas.length * nodeHeight + topPadding + 40.0;

        final centers = <Offset>[];
        for (int i = 0; i < levelDatas.length; i++) {
          final isLeft = i % 2 == 0;
          final x = isLeft ? sw * 0.30 : sw * 0.70;
          final y = topPadding + i * nodeHeight;
          centers.add(Offset(x, y));
        }

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: totalHeight,
            width: sw,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: RoadmapPainter(
                      centers: centers,
                      levels: levelDatas,
                    ),
                  ),
                ),
                for (int i = 0; i < levelDatas.length; i++)
                  Positioned(
                    left: (i % 2 == 0)
                        ? centers[i].dx - circleAreaSize / 2
                        : centers[i].dx - circleAreaSize / 2 - gap - cardWidth,
                    top: centers[i].dy - circleAreaSize / 2,
                    child: _buildNodeRow(
                      levelDatas[i],
                      isLeft: i % 2 == 0,
                      cardWidth: cardWidth,
                      gap: gap,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNodeRow(
    LevelData level, {
    required bool isLeft,
    required double cardWidth,
    required double gap,
  }) {
    final isLocked = level.status == LevelStatus.locked;
    final circleWidget = _buildCircleWithDots(level);
    final cardWidget = SizedBox(width: cardWidth, child: _buildCard(level));

    return GestureDetector(
      onTap: isLocked
          ? null
          : () async {
              final isComplete = level.status == LevelStatus.completed;
              final initialStep = isComplete
                  ? 1
                  : (level.completedCycles.length + 1)
                      .clamp(1, _cyclesPerLevel);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LearningActivityScreen(
                    levelData: level,
                    initialStep: initialStep,
                    subject: 'korean',
                    grade: _grade,
                    nickname: _nickname,
                    isReview: isComplete,
                    onStepCompleted: level.status != LevelStatus.locked
                        ? () {
                            _loadProgress();
                            widget.onAnyStepCompleted?.call();
                          }
                        : null,
                  ),
                ),
              );
              _loadProgress();
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [circleWidget, SizedBox(width: gap), cardWidget]
            : [cardWidget, SizedBox(width: gap), circleWidget],
      ),
    );
  }

  Widget _buildCycleDot(int dotIndex, int filledCount, bool isLocked) {
    final isFilled = dotIndex < filledCount;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? AppColors.primary
            : isLocked
                ? const Color(0xFFDCD5CA)
                : Colors.white,
        border: (!isFilled && !isLocked)
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
    );
  }

  Widget _buildCircleWithDots(LevelData level) {
    final isCompleted = level.status == LevelStatus.completed;
    final isCurrent = level.status == LevelStatus.current;
    final isLocked = level.status == LevelStatus.locked;

    final filledCount =
        isCompleted ? _cyclesPerLevel : level.completedCycles.length;

    final Color borderColor = isCompleted || isCurrent
        ? AppColors.primary
        : const Color(0xFFDCD5CA);
    final Color bgColor = isCompleted
        ? const Color(0xFFF0F8ED)
        : isCurrent
            ? Colors.white
            : const Color(0xFFF9F7F3);

    const containerSize = 150.0;
    const circleSize = 100.0;
    const circleInset = (containerSize - circleSize) / 2;
    const cx = containerSize / 2;
    const cy = containerSize / 2;
    const orbitRadius = 65.0;
    const dotSize = 12.0;

    final dotPositioned = <Widget>[
      for (int i = 0; i < _cyclesPerLevel; i++)
        () {
          final angle = -math.pi / 2 + i * 2 * math.pi / _cyclesPerLevel;
          final dx = cx + orbitRadius * math.cos(angle);
          final dy = cy + orbitRadius * math.sin(angle);
          return Positioned(
            left: dx - dotSize / 2,
            top: dy - dotSize / 2,
            child: _buildCycleDot(i, filledCount, isLocked),
          );
        }(),
    ];

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: circleInset,
            top: circleInset,
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: 5,
                    ),
                  if (isCompleted)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 46)
                    : isCurrent
                        ? const Icon(Icons.eco_rounded,
                            color: AppColors.primary, size: 44)
                        : Icon(Icons.lock_outline_rounded,
                            color: Colors.grey.shade400, size: 34),
              ),
            ),
          ),
          ...dotPositioned,
        ],
      ),
    );
  }

  Widget _buildCard(LevelData level) {
    final isLocked = level.status == LevelStatus.locked;
    final labelColor = isLocked ? AppColors.textSub : AppColors.primary;
    final titleColor = isLocked ? AppColors.textSub : AppColors.textMain;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLocked
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.title,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: labelColor),
          ),
          const SizedBox(height: 3),
          Text(
            level.description,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: titleColor),
          ),
          if (level.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              level.subtitle,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub),
            ),
          ],
        ],
      ),
    );
  }
}
