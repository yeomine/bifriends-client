import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/parent_service.dart';
import 'onboarding_screen.dart';

class ParentSetupScreen extends StatefulWidget {
  const ParentSetupScreen({super.key});

  @override
  State<ParentSetupScreen> createState() => _ParentSetupScreenState();
}

class _ParentSetupScreenState extends State<ParentSetupScreen> {
  final PageController _pageController = PageController();
  final _parentService = ParentService();
  int _currentStep = 0;

  String _pin = '';
  String _confirmPin = '';
  bool _pinError = false;
  bool _isLoading = false;

  Future<void> _nextStep() async {
    if (_currentStep == 1 && _pin.length < 4) return;
    if (_currentStep == 2 && _confirmPin.length < 4) return;

    if (_currentStep == 2) {
      if (_pin != _confirmPin) {
        setState(() {
          _pinError = true;
          _confirmPin = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호가 일치하지 않습니다. 다시 입력해주세요.'),
            backgroundColor: Color(0xFFF07D4F),
          ),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        await _parentService.resetPassword(_pin, _confirmPin);
        if (mounted) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('비밀번호 설정에 실패했어요. 다시 시도해 주세요.'),
              backgroundColor: Color(0xFFF07D4F),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNumpadTap(String value) {
    setState(() {
      _pinError = false;
      if (_currentStep == 1) {
        if (_pin.length < 4) _pin += value;
      } else if (_currentStep == 2) {
        if (_confirmPin.length < 4) _confirmPin += value;
      }
    });
  }

  void _onNumpadDelete() {
    setState(() {
      _pinError = false;
      if (_currentStep == 1 && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_currentStep == 2 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildWelcomeStep(),
                  _buildPinSetupStep(),
                  _buildPinConfirmStep(),
                  _buildHandoverStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            'assets/images/leo_default.png',
            height: 140,
            errorBuilder: (context, error, stackTrace) =>
                const Text('🦫', style: TextStyle(fontSize: 100)),
          ),
          const SizedBox(height: 32),
          Text(
            '반가워요! 저는 레오예요.👋',
            style: GoogleFonts.gaegu(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B4423),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '아이와 함께 BIFriends를 시작해볼까요?\n따뜻하고 재미있는 공부방을 함께 만들어봐요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A7E74),
              height: 1.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _nextStep,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '부모님 모드 설정하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPinSetupStep() {
    return _buildPinStepWrapper(
      icon: Icons.person_outline,
      iconColor: const Color(0xFF8B6D55),
      title: '부모님 비밀번호 설정',
      subtitle: '아이의 성장을 관리할 때 필요한 4자리 숫자예요.',
      currentPin: _pin,
      buttonText: '다음',
      onButtonPressed: _nextStep,
    );
  }

  Widget _buildPinConfirmStep() {
    return _buildPinStepWrapper(
      icon: Icons.verified_user_outlined,
      iconColor: const Color(0xFF527052),
      title: '한 번 더 입력해주세요',
      subtitle: '비밀번호가 맞는지 확인이 필요해요.',
      currentPin: _confirmPin,
      buttonText: '확인',
      onButtonPressed: _nextStep,
      isError: _pinError,
    );
  }

  Widget _buildPinStepWrapper({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String currentPin,
    required String buttonText,
    required VoidCallback onButtonPressed,
    bool isError = false,
  }) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B4423),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A7E74),
          ),
        ),
        const SizedBox(height: 40),
        _buildPinIndicators(currentPin, isError),
        const Spacer(),
        _buildNumpad(
          currentPinLength: currentPin.length,
          buttonText: buttonText,
          onActionPressed: onButtonPressed,
        ),
      ],
    );
  }

  Widget _buildPinIndicators(String currentPin, bool isError) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: isFilled ? const Color(0xFF3D5A3C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError
                  ? const Color(0xFFF07D4F)
                  : (isFilled
                        ? const Color(0xFF3D5A3C)
                        : const Color(0xFFE8E0D5)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isFilled
                ? const Text(
                    '*',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumpad({
    required int currentPinLength,
    required String buttonText,
    required VoidCallback onActionPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Row(
            children: [
              _buildNumpadButton('1'),
              _buildNumpadButton('2'),
              _buildNumpadButton('3'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNumpadButton('4'),
              _buildNumpadButton('5'),
              _buildNumpadButton('6'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNumpadButton('7'),
              _buildNumpadButton('8'),
              _buildNumpadButton('9'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNumpadAction(
                label: '지우기',
                color: const Color(0xFFFFF0F0),
                textColor: const Color(0xFFFF5C5C),
                onTap: _onNumpadDelete,
              ),
              _buildNumpadButton('0'),
              _buildNumpadAction(
                label: _isLoading ? '...' : buttonText,
                color: (currentPinLength == 4 && !_isLoading)
                    ? const Color(0xFF3D5A3C)
                    : const Color(0xFF8B9D8A),
                textColor: Colors.white,
                onTap: (currentPinLength == 4 && !_isLoading) ? onActionPressed : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: () => _onNumpadTap(number),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B4423),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadAction({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: onTap != null
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandoverStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Image.asset(
            'assets/images/leo_default.png',
            height: 160,
            errorBuilder: (context, error, stackTrace) =>
                const Text('🦫', style: TextStyle(fontSize: 120)),
          ),
          const SizedBox(height: 32),
          Text(
            '좋아요! 이제 아이를 불러주세요.',
            style: GoogleFonts.gaegu(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B4423),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '함께 설정판을 완성해봐요!',
            style: GoogleFonts.gaegu(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D5A3C),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '레오랑 친구 하러 가자~',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A7E74),
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6D55),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              },
              child: const Text(
                '어린이 친구와 함께 계속하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
