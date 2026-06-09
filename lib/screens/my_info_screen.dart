import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/member_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final _memberService = MemberService();
  final _authService = AuthService();
  final _nicknameController = TextEditingController();

  int _grade = 3;
  List<String> _selectedInterests = [];
  bool _isLoading = true;
  bool _isSaving = false;

  static const _gradeOptions = [3, 4, 5, 6];
  static const _maxInterests = 3;
  static const _interestItems = [
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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final member = await _memberService.getMe();
      if (mounted) {
        setState(() {
          _nicknameController.text = member.nickname ?? member.name;
          _grade = member.grade ?? 3;
          _selectedInterests = List<String>.from(member.interests);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _memberService.updateSettings(
        nickname: nickname,
        grade: _grade,
        interests: _selectedInterests,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장됐어요!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 정보',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textMain),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('닉네임'),
                  const SizedBox(height: 10),
                  _buildNicknameField(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('학년'),
                  const SizedBox(height: 10),
                  _buildGradeSelector(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('관심사 (최대 $_maxInterests개)'),
                  const SizedBox(height: 10),
                  _buildInterestGrid(),
                  const SizedBox(height: 48),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSub,
      ),
    );
  }

  Widget _buildNicknameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _nicknameController,
        maxLength: 12,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '닉네임을 입력해주세요',
          hintStyle: const TextStyle(color: AppColors.textSub),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGradeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _gradeOptions.map((g) {
        final isSelected = _grade == g;
        return GestureDetector(
          onTap: () => setState(() => _grade = g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$g학년',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSub,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: _interestItems.map((item) {
        final id = item['id'] as String;
        final name = item['name'] as String;
        final icon = item['icon'] as IconData;
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
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: isSelected ? Colors.white : AppColors.textSub,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await _authService.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textMain,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          '로그아웃',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
