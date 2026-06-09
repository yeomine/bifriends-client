import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/member_model.dart';
import '../services/member_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'main_scaffold.dart';
import 'parent_mode_auth_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  final MemberService _memberService = MemberService();
  bool _isLoading = true;
  String _displayName = '친구';
  String _errorMessage = '';
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final member = await _memberService.getMe();
      if (mounted) {
        setState(() {
          _displayName = member.nickname ?? member.name;
          if (_displayName.isEmpty) _displayName = '친구';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('401')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          setState(() {
            _errorMessage = '정보를 불러오는데 실패했어요.\n$e';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onStartPressed() {
    if (_selectedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScaffold()),
      );
    } else if (_selectedIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ParentModeAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Text(
                'BIFriends',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '누가 레오랑 놀 건가요? 🦫✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProfileCard(
                    index: 0,
                    title: _displayName,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.asset(
                        'assets/images/leo_defaultface.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('🦫', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _buildProfileCard(
                    index: 1,
                    title: '보호자',
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 60,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedIndex != null ? _onStartPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primaryDisabled.withOpacity(0.4),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required int index,
    required String title,
    required Widget child,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(child: child),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? AppColors.textMain
                  : AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}
