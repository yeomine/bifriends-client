import 'package:flutter/material.dart';
import '../services/home_service.dart';
import '../theme/app_colors.dart';
import 'story_loading_screen.dart';
import 'mind_sessions_screen.dart';

class FriendsScreen extends StatefulWidget {
  final String? pendingTodoId;
  final VoidCallback? onTodoCompleted;

  const FriendsScreen({super.key, this.pendingTodoId, this.onTodoCompleted});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final HomeService _homeService = HomeService();
  String? _selectedEmotion;
  String? _pendingTodoId;

  @override
  void initState() {
    super.initState();
    _pendingTodoId = widget.pendingTodoId;
  }

  @override
  void didUpdateWidget(FriendsScreen old) {
    super.didUpdateWidget(old);
    if (widget.pendingTodoId != null && widget.pendingTodoId != old.pendingTodoId) {
      _pendingTodoId = widget.pendingTodoId;
    }
  }

  static const List<_EmotionItem> _emotions = [
    _EmotionItem(label: '기쁨', emoji: '😊', value: '기쁨'),
    _EmotionItem(label: '속상함', emoji: '😢', value: '속상함'),
    _EmotionItem(label: '화남', emoji: '😠', value: '화남'),
    _EmotionItem(label: '부끄러움', emoji: '😳', value: '부끄러움'),
    _EmotionItem(label: '고마움', emoji: '🙏', value: '고마움'),
    _EmotionItem(label: '실망', emoji: '😔', value: '실망'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5C9B8),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/leo_defaultface.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '오늘 친구는 어떤 기분일까요?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '배우고 싶은 감정을 선택해봐요!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _emotions.map((item) {
                          final isSelected = _selectedEmotion == item.value;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedEmotion = item.value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFEBE6DF),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedEmotion == null
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StoryLoadingScreen(
                                      emotion: _selectedEmotion!,
                                    ),
                                  ),
                                );
                                if (_pendingTodoId != null) {
                                  final todoId = _pendingTodoId!;
                                  _pendingTodoId = null;
                                  try {
                                    await _homeService.completeTodo(todoId);
                                  } catch (_) {}
                                  widget.onTodoCompleted?.call();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primaryDisabled,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '이야기 보러 가기!',
                          style: TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '친구랑',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '오늘은 레오랑 어떤 표현을 배우게 될까요? 🤩',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MindSessionsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.history,
              color: AppColors.textSub,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmotionItem {
  final String label;
  final String emoji;
  final String value;

  const _EmotionItem({
    required this.label,
    required this.emoji,
    required this.value,
  });
}
