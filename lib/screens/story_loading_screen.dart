import 'dart:async';
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
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;
  late final AnimationController _tipFadeController;
  late final Animation<double> _tipFadeAnim;

  Timer? _tipTimer;
  int _tipIndex = 0;

  bool _hasError = false;
  bool _isRetrying = false;

  static const List<_TipItem> _tips = [
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '레오는 카피바라야! 카피바라는 세상에서 가장 큰 설치류로, 다 자라면 몸무게가 최대 65kg까지 나가기도 해!',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '플라밍고는 원래 흰색이야! 새우를 먹어서 분홍색으로 변하는 거래. 먹는 게 몸 색깔을 바꾸다니 신기하지?',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라는 악어나 원숭이, 새들도 등에 태우고 다녀! 모두와 친하게 지내는 동물로 유명해.',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '하루에 눈을 깜빡이는 횟수가 약 14,000번이야! 지금 이 순간에도 나도 모르게 깜빡이고 있어.',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라는 물속에서 잠을 자기도 해! 코만 물 위로 내밀고 꾸벅꾸벅 졸아. 레오도 그럴까? 💤',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '사람 몸속 혈관을 전부 이으면 지구를 두 바퀴 반이나 돌 수 있는 길이래! 우리 몸이 엄청나지?',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '레오 같은 카피바라는 눈, 코, 귀가 모두 머리 위쪽에 있어서 물에 잠긴 채로도 주변을 살필 수 있어!',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '코끼리는 점프를 전혀 못해! 지구상 포유류 중 점프를 못 하는 건 코끼리뿐이래.',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라는 달릴 때 최대 시속 35km까지 낼 수 있어! 웬만한 자전거보다 빠르지.',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '사람은 태어날 때 무릎뼈가 없어! 3~5살이 지나야 무릎뼈가 생기기 시작한대.',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라 새끼는 태어난 지 몇 시간 만에 혼자 걷고 헤엄칠 수 있어! 레오도 태어나자마자 수영 선수였겠지?',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '북극곰 털은 사실 투명해! 햇빛을 반사해서 하얗게 보이는 거야. 진짜 색깔은 없는 거래!',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라는 "크릭", "휘휘", "캥" 같은 7가지 이상의 소리로 친구들과 대화해! 진짜 언어가 있는 거야.',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '눈송이는 세상에 하나도 똑같은 모양이 없어! 지금까지 발견된 눈송이가 모두 제각각 달랐대.',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라는 발가락 사이에 물갈퀴가 있어서 수영을 아주 잘해! 레오가 수영을 좋아하는 이유야.',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '개미는 자기 몸무게의 50배를 들 수 있어! 사람으로 치면 코끼리를 번쩍 드는 것과 같아.',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라는 피부가 건조해지면 안 돼서 하루에도 여러 번 물속에 들어가야 해. 레오는 목욕을 정말 좋아해!',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '꿀벌 한 마리가 평생 만드는 꿀은 티스푼 하나도 안 돼! 꿀이 정말 소중한 이유야. 🍯',
    ),
    _TipItem(
      category: '레오 이야기',
      icon: '🦫',
      text: '카피바라 이빨은 평생 계속 자라나! 딱딱한 풀을 씹으면서 자연스럽게 갈려서 항상 적당한 길이를 유지해.',
    ),
    _TipItem(
      category: '알고 있었어?',
      icon: '💡',
      text: '사람의 뼈는 태어날 때 300개인데, 어른이 되면 206개로 줄어들어! 자라면서 뼈들이 서로 붙는 거래.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _tipFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _tipFadeAnim = CurvedAnimation(
      parent: _tipFadeController,
      curve: Curves.easeInOut,
    );

    _startTipCycle();
    _loadScenario();
  }

  void _startTipCycle() {
    _tipTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      await _tipFadeController.reverse();
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      _tipFadeController.forward();
    });
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
    _bounceController.dispose();
    _tipFadeController.dispose();
    _tipTimer?.cancel();
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
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(child: _hasError ? _buildErrorView() : _buildLoadingView()),
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
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
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _tipFadeAnim,
            child: _buildTipCard(_tips[_tipIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(_TipItem tip) {
    final isLeo = tip.category == '레오 이야기';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isLeo
                  ? const Color(0xFFF5C9B8).withValues(alpha: 0.7)
                  : AppColors.hint.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tip.icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  tip.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLeo
                        ? AppColors.textMain
                        : const Color(0xFF7A5C0A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tip.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              height: 1.65,
            ),
          ),
        ],
      ),
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

class _TipItem {
  final String category;
  final String icon;
  final String text;

  const _TipItem({
    required this.category,
    required this.icon,
    required this.text,
  });
}
