import 'package:flutter/material.dart';
import '../models/mind_model.dart';
import '../services/mind_service.dart';
import '../theme/app_colors.dart';
import 'friends_activity_screen.dart';

class MindSessionsScreen extends StatefulWidget {
  const MindSessionsScreen({super.key});

  @override
  State<MindSessionsScreen> createState() => _MindSessionsScreenState();
}

class _MindSessionsScreenState extends State<MindSessionsScreen> {
  List<MindSessionSummary>? _sessions;
  bool _isLoading = true;
  String? _errorMessage;

  static const Map<String, String> _emotionEmoji = {
    '기쁨': '😊',
    '속상함': '😢',
    '화남': '😠',
    '부끄러움': '😳',
    '고마움': '🙏',
    '실망': '😔',
  };

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sessions = await MindService().getSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSessionTap(MindSessionSummary summary) async {
    try {
      final scenario = await MindService().getSession(summary.setId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendsActivityScreen(
            scenario: scenario,
            isReview: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('세션을 불러오지 못했어요: $e'),
          backgroundColor: const Color(0xFFD04B44),
        ),
      );
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '지난 마음 여행',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😢', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                '불러오지 못했어요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadSessions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final sessions = _sessions ?? [];

    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌱', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              '아직 마음 여행 기록이 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '레오와 함께 첫 번째 여행을 떠나봐요!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSub,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: sessions.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSessionCard(sessions[index]),
    );
  }

  Widget _buildSessionCard(MindSessionSummary session) {
    final emoji = _emotionEmoji[session.emotion] ?? '💭';

    return GestureDetector(
      onTap: () => _onSessionTap(session),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.emotion,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      if (session.isFallback) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5ECD8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '기본',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${session.learnedExpression}"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSub,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(session.completedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSub,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
