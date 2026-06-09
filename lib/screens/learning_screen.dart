import 'package:flutter/material.dart';
import '../widgets/learning_roadmap.dart';
import '../widgets/korean_learning_roadmap.dart';
import '../theme/app_colors.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '어떤 힘을 키워볼까?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '하나씩 천천히 해보자!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _CategoryCard(
                        tag: '수학이랑 친해지기',
                        title: '생각하는 힘 키우기',
                        subtitle: '도형이랑 숫자로 똑똑해지자! 🧠',
                        icon: Icons.psychology,
                        iconColor: const Color(0xFFE07B39),
                        iconBgColor: const Color(0xFFFFF0E4),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LearningRoadmapScreen(
                              title: '생각하는 힘 키우기',
                              subject: 'math',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _CategoryCard(
                        tag: '문장 만들기 연습',
                        title: '말하는 힘 키우기',
                        subtitle: '레오랑 같이 예쁜 문장을 만들어봐! 💬',
                        icon: Icons.chat_bubble_outline,
                        iconColor: AppColors.primary,
                        iconBgColor: const Color(0xFFE4F0E4),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LearningRoadmapScreen(
                              title: '말하는 힘 키우기',
                              subject: 'korean',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              tag,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LearningRoadmapScreen extends StatelessWidget {
  const LearningRoadmapScreen({required this.title, required this.subject});

  final String title;
  final String subject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: subject == 'math'
          ? const LearningRoadmap()
          : const KoreanLearningRoadmap(),
    );
  }
}
