import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/onboarding_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import 'main_scaffold.dart';

class SpeechBubbleShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(bottom: 16);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height - 16),
      const Radius.circular(20),
    );
    final path = Path()..addRRect(rrect);

    path.moveTo(rect.left + 30, rect.bottom - 16);
    path.lineTo(rect.left + 35, rect.bottom);
    path.lineTo(rect.left + 45, rect.bottom - 16);
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _currentPage = 0;
  static const int _totalPages = 6;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  int? _selectedGrade;
  final List<String> _selectedInterests = [];
  String? _selectedGift;

  static const int _maxInterests = 3;

  final List<Map<String, dynamic>> _interestItems = const [
    {'id': 'DINOSAUR', 'name': '공룡', 'icon': Icons.pets},
    {'id': 'ANIMAL', 'name': '동물', 'icon': Icons.cruelty_free},
    {'id': 'SPACE', 'name': '우주', 'icon': Icons.rocket_launch},
    {'id': 'SPORTS', 'name': '운동', 'icon': Icons.fitness_center},
    {'id': 'KPOP_MUSIC', 'name': '음악', 'icon': Icons.music_note},
    {'id': 'GAME', 'name': '게임', 'icon': Icons.sports_esports},
    {'id': 'COOKING', 'name': '요리', 'icon': Icons.restaurant_menu},
    {'id': 'CRAFTING', 'name': '만들기', 'icon': Icons.palette},
    {'id': 'SCIENCE', 'name': '과학', 'icon': Icons.science},
  ];

  final List<Map<String, dynamic>> _giftItems = const [
    {'id': 'GIFT_1', 'name': '책', 'icon': Icons.book, 'image': 'studying'},
    {'id': 'GIFT_2', 'name': '리본', 'icon': Icons.redeem, 'image': 'ribbon'},
    {
      'id': 'GIFT_3',
      'name': '꽃',
      'icon': Icons.filter_vintage,
      'image': 'flower',
    },
    {
      'id': 'GIFT_4',
      'name': '선글라스',
      'icon': Icons.sunny,
      'image': 'sunglasses',
    },
  ];

  Future<void> _nextPage() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      if (_currentPage == 1) {
        await _onboardingService.updateProfile(
          nickname: _userName,
          grade: _selectedGrade!,
        );
      } else if (_currentPage == 2) {
        await _onboardingService.updateInterests(interests: _selectedInterests);
      } else if (_currentPage == 4) {
        await _onboardingService.selectGift(itemType: _selectedGift!);
      } else if (_currentPage == 5) {
        // 권한 요청
        final Map<Permission, PermissionStatus> statuses = await [
          Permission.notification,
          Permission.microphone,
        ].request();

        final bool notificationEnabled =
            statuses[Permission.notification]?.isGranted ?? false;
        final bool microphoneEnabled =
            statuses[Permission.microphone]?.isGranted ?? false;

        await _onboardingService.updatePermissions(
          notificationEnabled: notificationEnabled,
          microphoneEnabled: microphoneEnabled,
        );

        await _onboardingService.completeOnboarding();
      }

      setState(() => _isLoading = false);

      if (_currentPage < _totalPages - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScaffold(isFirstVisit: true),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  String get _userName => _nameController.text.trim();

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildNameInputPage(),
                  _buildGradePage(),
                  _buildInterestPage(),
                  _buildGreetingPage(),
                  _buildGiftPage(),
                  _buildFinalPage(),
                ],
              ),
            ),
            if (_currentPage > 0)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: AppColors.textMain,
                  ),
                  onPressed: _isLoading ? null : _prevPage,
                ),
              ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasJongseong(String str) {
    if (str.isEmpty) return false;
    final lastChar = str.runes.last;
    if (lastChar < 0xAC00 || lastChar > 0xD7A3) return false;
    return (lastChar - 0xAC00) % 28 > 0;
  }

  Widget _buildTopProgressBar(int step) {
    final progress = (step + 1) / 5;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Container(
        height: 6,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.textSub,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SpeechBubbleShape(),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.gaegu(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildCharacter({double size = 120, String? overrideImage}) {
    final String assetPath = overrideImage ?? 'assets/images/leo_default.png';
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text('🦫', style: TextStyle(fontSize: size * 0.8)),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: isActive ? 4 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: (isActive && !_isLoading) ? onPressed : null,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildPageWrapper({
    required int step,
    required Widget child,
    required String buttonText,
    required bool buttonActive,
    required VoidCallback onButtonPressed,
    bool showProgressBar = true,
  }) {
    return Column(
      children: [
        const SizedBox(height: 48),
        if (showProgressBar) _buildTopProgressBar(step),
        Expanded(child: child),
        _buildActionButton(
          text: buttonText,
          isActive: buttonActive,
          onPressed: onButtonPressed,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNameInputPage() {
    return _buildPageWrapper(
      step: 0,
      buttonText: '다음',
      buttonActive: _userName.isNotEmpty,
      onButtonPressed: _nextPage,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildCharacter(size: 100),
          const SizedBox(height: 12),
          _buildSpeechBubble('불리고 싶은 이름을 적어줘!'),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
              decoration: const InputDecoration(
                hintText: '닉네임 입력',
                hintStyle: TextStyle(
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGradePage() {
    return _buildPageWrapper(
      step: 1,
      buttonText: '다음',
      buttonActive: _selectedGrade != null,
      onButtonPressed: _nextPage,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildCharacter(size: 100),
          const SizedBox(height: 12),
          _buildSpeechBubble('너는 몇 학년이야?'),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: List.generate(4, (index) {
              final grade = index + 3;
              final isSelected = _selectedGrade == grade;
              return GestureDetector(
                onTap: () => setState(() => _selectedGrade = grade),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textSub : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textSub
                          : AppColors.borderLight,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$grade',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textMain,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildInterestPage() {
    return _buildPageWrapper(
      step: 2,
      buttonText: '다음',
      buttonActive: _selectedInterests.isNotEmpty,
      onButtonPressed: _nextPage,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            '어떤 걸 좋아해?',
            style: GoogleFonts.gaegu(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: _interestItems.map((item) {
                final id = item['id'] as String;
                final name = item['name'] as String;
                final isSelected = _selectedInterests.contains(id);
                final canSelect = _selectedInterests.length < _maxInterests;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(id);
                      } else if (canSelect) {
                        _selectedInterests.add(id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.textSub : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.textSub
                            : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 28,
                          color: isSelected ? Colors.white : AppColors.textMain,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingPage() {
    final displayName = _userName.isEmpty ? '친구' : _userName;
    final particle = _hasJongseong(displayName) ? '아' : '야';
    return _buildPageWrapper(
      step: 3,
      buttonText: '나도 반가워!',
      buttonActive: true,
      onButtonPressed: _nextPage,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSpeechBubble('$displayName$particle, 만나서 반가워! 😊'),
          const Spacer(),
          _buildCharacter(size: 180),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildGiftPage() {
    final displayName = _userName.isEmpty ? '친구' : _userName;
    final particle = _hasJongseong(displayName) ? '아' : '야';
    String? currentImage;
    if (_selectedGift != null) {
      final selectedItem = _giftItems.firstWhere(
        (item) => item['id'] == _selectedGift,
      );
      currentImage = 'assets/images/leo_${selectedItem['image']}.png';
    }
    return _buildPageWrapper(
      step: 4,
      buttonText: '이걸로 할래!',
      buttonActive: _selectedGift != null,
      onButtonPressed: _nextPage,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSpeechBubble('$displayName$particle,\n나한테 선물 하나만 골라줘!'),
          const SizedBox(height: 16),
          _buildCharacter(size: 160, overrideImage: currentImage),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: _giftItems.map((item) {
              final isSelected = _selectedGift == item['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedGift = item['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE5E9D8)
                        : const Color(0xFFF4EFE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF738A58)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 28,
                        color: isSelected
                            ? AppColors.textMain
                            : AppColors.textSub,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['name'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.textMain
                              : AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    final displayName = _userName.isEmpty ? '친구' : _userName;
    final particle = _hasJongseong(displayName) ? '이의' : '의';
    String? finalImage;
    if (_selectedGift != null) {
      final selectedItem = _giftItems.firstWhere(
        (item) => item['id'] == _selectedGift,
      );
      finalImage = 'assets/images/leo_${selectedItem['image']}.png';
    }
    return _buildPageWrapper(
      step: 5,
      showProgressBar: false,
      buttonText: '응, 좋아!',
      buttonActive: true,
      onButtonPressed: _nextPage,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSpeechBubble(
            '부모님께도 매주 $displayName$particle \n발달 소식을 알려드릴게!\n부모님이 정말 좋아하실 거야! 😊',
          ),
          const Spacer(),
          _buildCharacter(size: 180, overrideImage: finalImage),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
