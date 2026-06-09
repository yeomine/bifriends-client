import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GuideTourStep { welcomePopup, homeTab, learningTab, chatTab, heartTab }

class GuideTourStepInfo {
  final String title;
  final String description;
  final String buttonText;
  final IconData icon;

  const GuideTourStepInfo({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.icon,
  });
}

const Map<GuideTourStep, GuideTourStepInfo> guideTourStepInfoMap = {
  GuideTourStep.welcomePopup: GuideTourStepInfo(
    title: '반가워! 🦫',
    description: '앱을 처음 켠 너를 위해\n간단히 소개해 줄게!',
    buttonText: '구경하러 가기',
    icon: Icons.waving_hand,
  ),
  GuideTourStep.homeTab: GuideTourStepInfo(
    title: '홈 🏠',
    description: '오늘 할 일이랑 레오의 모습을\n여기서 한눈에 볼 수 있어!',
    buttonText: '다음',
    icon: Icons.home,
  ),
  GuideTourStep.learningTab: GuideTourStepInfo(
    title: '공부방 📚',
    description: '여기서 다양한 학습을\n재밌게 할 수 있어!',
    buttonText: '다음',
    icon: Icons.menu_book,
  ),
  GuideTourStep.chatTab: GuideTourStepInfo(
    title: '레오랑 톡톡 💬',
    description: '레오와 이야기하면서\n궁금한 걸 물어볼 수 있어!',
    buttonText: '다음',
    icon: Icons.chat_bubble,
  ),

  GuideTourStep.heartTab: GuideTourStepInfo(
    title: '친구랑 💚',
    description: '오늘 내 기분을 기록하고\n감정을 배울 수 있어!',
    buttonText: '열심히 해볼게!',
    icon: Icons.people,
  ),
};

class GuideTourOverlay extends StatefulWidget {
  final GuideTourStep currentStep;
  final GlobalKey? spotlightTargetKey;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const GuideTourOverlay({
    super.key,
    required this.currentStep,
    this.spotlightTargetKey,
    required this.onNext,
    required this.onFinish,
  });

  @override
  State<GuideTourOverlay> createState() => _GuideTourOverlayState();
}

class _GuideTourOverlayState extends State<GuideTourOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant GuideTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Rect? _getSpotlightRect() {
    if (widget.spotlightTargetKey == null) return null;
    final renderBox =
        widget.spotlightTargetKey!.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    const padding = 8.0;
    return Rect.fromLTWH(
      position.dx - padding,
      position.dy - padding,
      size.width + padding * 2,
      size.height + padding * 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepInfo = guideTourStepInfoMap[widget.currentStep]!;
    final isWelcome = widget.currentStep == GuideTourStep.welcomePopup;
    final spotlightRect = isWelcome ? null : _getSpotlightRect();
    final bottomOffset = spotlightRect != null
        ? MediaQuery.of(context).size.height - spotlightRect.top + 20
        : MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight / 2 +
              80;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(spotlightRect: spotlightRect),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          if (spotlightRect != null)
            Positioned(
              left: spotlightRect.left - 6,
              top: spotlightRect.top - 6,
              child: IgnorePointer(
                child: Container(
                  width: spotlightRect.width + 12,
                  height: spotlightRect.height + 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isWelcome)
            _buildWelcomePopup(stepInfo, bottomOffset)
          else
            _buildTabGuide(stepInfo, spotlightRect, bottomOffset),
        ],
      ),
    );
  }

  Widget _buildWelcomePopup(GuideTourStepInfo stepInfo, double bottomOffset) {
    return Positioned(
      left: 32,
      right: 32,
      bottom: bottomOffset,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1DF),
                  shape: BoxShape.circle,
                ),
                child: const Text('🦫', style: TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 24),
              Text(
                stepInfo.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                stepInfo.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: widget.onNext,
                  child: Text(
                    stepInfo.buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabGuide(
    GuideTourStepInfo stepInfo,
    Rect? spotlightRect,
    double bottomOffset,
  ) {
    final isLastStep = widget.currentStep == GuideTourStep.heartTab;

    return Positioned(
      left: 32,
      right: 32,
      bottom: bottomOffset,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1DF),
                  shape: BoxShape.circle,
                ),
                child: Icon(stepInfo.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                stepInfo.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stepInfo.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final stepIndex = widget.currentStep.index - 1;
                  return Container(
                    width: index == stepIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == stepIndex
                          ? AppColors.primary
                          : const Color(0xFFE0D8CC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastStep
                        ? const Color(0xFFF07D4F)
                        : null,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLastStep ? widget.onFinish : widget.onNext,
                  child: Text(
                    stepInfo.buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;

  _SpotlightPainter({this.spotlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (spotlightRect != null) {
      final path = Path()
        ..addRect(fullRect)
        ..addRRect(
          RRect.fromRectAndRadius(spotlightRect!, const Radius.circular(16)),
        )
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(path, paint);
    } else {
      canvas.drawRect(fullRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect;
  }
}
