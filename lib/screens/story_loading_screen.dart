import 'package:flutter/material.dart';
import '../services/mind_service.dart';
import '../theme/app_colors.dart';
import 'friends_activity_screen.dart';

class StoryLoadingScreen extends StatefulWidget {
  final String emotion;

  const StoryLoadingScreen({super.key, required this.emotion});

  @override
  State<StoryLoadingScreen> createState() => _StoryLoadingScreenState();
}

class _StoryLoadingScreenState extends State<StoryLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnim;

  bool _hasError = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(
      begin: 0,
      end: -12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _loadScenario();
  }

  Future<void> _loadScenario() async {
    setState(() {
      _hasError = false;
      _isRetrying = false;
    });

    try {
      final scenario = await MindService().generateScenario(widget.emotion);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FriendsActivityScreen(scenario: scenario),
        ),
      );
    } catch (e, st) {
      debugPrint('[StoryLoadingScreen] 시나리오 로드 실패: $e');
      debugPrint('[StoryLoadingScreen] 스택트레이스: $st');
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await _loadScenario();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _hasError ? _buildErrorView() : _buildLoadingView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: child,
          ),
          child: Image.asset(
            'assets/images/leo_defaultface.png',
            width: 110,
            height: 110,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '레오가 특별한 마음 여행을\n준비하고 있어!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '잠시만 기다려줘..!!',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSub,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/leo_defaultface.png',
            width: 90,
            height: 90,
            color: AppColors.textSub,
            colorBlendMode: BlendMode.saturation,
          ),
          const SizedBox(height: 28),
          const Text(
            '레오가 잠시 자리를 비웠어요 😅',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '이야기 준비 중에 문제가 생겼어요.\n잠시 후 다시 시도해 주세요!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRetrying ? null : _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primaryDisabled,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isRetrying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '다시 시도하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '돌아가기',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
