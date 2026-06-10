import 'package:flutter/material.dart';
import 'package:bifriends_client/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_toast.dart';
import 'guardian_consent_screen.dart';
import 'mode_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (response != null) {
        // 임시 테스트용으로 온보딩 상태와 무관하게 항상 온보딩 화면으로 이동하도록 수정된 부분
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const GuardianConsentScreen(),
        //     ),
        //   );
        if (response.onboardingCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ModeSelectionScreen(),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GuardianConsentScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '로그인 중 오류가 발생했습니다.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8DFD0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/leo_default.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '안녕! 나는 레오야',
                  style: GoogleFonts.gaegu(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF6B4423),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '너랑 같이 공부하고 이야기하고 싶어!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A7E74),
                    height: 1.6,
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '→',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                '구글로 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
