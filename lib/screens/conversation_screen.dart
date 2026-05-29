import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/stt_service.dart';
import '../theme/app_colors.dart';

class ConversationScreen extends StatefulWidget {
  // TODO: BE 연동 시 실제 닉네임 전달
  final String nickname;

  const ConversationScreen({super.key, this.nickname = '정우치치'});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isHistoryOpen = false;
  bool _isSessionsExpanded = false;
  bool _isListening = false;
  bool _isTranscribing = false;
  final SttService _sttService = SttService();

  // TODO: BE 연동 시 API로 교체
  String _activeSessionId = 'session_1';
  final List<ChatSession> _sessions = [
    ChatSession(id: 'session_1', title: '안녕 카피바라!', createdAt: DateTime.now()),
    ChatSession(
      id: 'session_2',
      title: '리오와의 첫 인사',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ChatSession(
      id: 'session_3',
      title: '내일 어떤 음식을 만들까?',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // TODO: BE 연동 시 세션별 메시지 로드로 교체 (_messages가 비어있으면 웰컴 화면 표시)
  List<ChatMessage> _messages = [];

  static const List<(String, String)> _quickReplies = [
    ('🔢', '수학이 어려워'),
    ('📖', '국어 도와줘'),
    ('💬', '그냥 레오랑 이야기 나누고 싶어'),
    ('✅', '오늘 할 일 적을게'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sttService.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isTranscribing) return;

    if (_isListening) {
      setState(() {
        _isListening = false;
        _isTranscribing = true;
      });
      final result = await _sttService.stopAndTranscribe();
      setState(() {
        _isTranscribing = false;
        if (result != null && result.isNotEmpty) {
          _messageController.text = result;
        }
      });
    } else {
      final hasPermission = await _sttService.hasPermission();
      if (!hasPermission) return;
      await _sttService.startRecording();
      setState(() => _isListening = true);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    // TODO: BE 연동 시 AI 응답 API 호출
    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          content: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];
    });
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuickReply(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  // 받침 있으면 '아', 없으면 '야'
  String _vocativeParticle(String name) {
    if (name.isEmpty) return '야';
    final code = name.codeUnitAt(name.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return '야';
    return (code - 0xAC00) % 28 == 0 ? '야' : '아';
  }

  // TODO: BE 연동 시 제거 — 세션 ID로 실제 메시지 로드
  List<ChatMessage> _mockMessagesForSession(String sessionId) {
    final title = _sessions.firstWhere((s) => s.id == sessionId).title;
    return [
      ChatMessage(
        id: '${sessionId}_1',
        content: '안녕! 나랑 이야기할래?\n오늘 기분은 어때?',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: '${sessionId}_2',
        content: title,
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width * 0.78;

    return Stack(
      children: [
        Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildMessagesList()),
            _buildInputBar(),
          ],
        ),
        if (_isHistoryOpen)
          GestureDetector(
            onTap: () => setState(() => _isHistoryOpen = false),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          left: _isHistoryOpen ? 0 : -panelWidth,
          top: 0,
          bottom: 0,
          width: panelWidth,
          child: _buildHistoryPanel(),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textMain, size: 24),
            onPressed: () => setState(() => _isHistoryOpen = true),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundImage: const AssetImage(
                    'assets/images/leo_default.png',
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '레오',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      '${_sessions.length} 대화 중',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.volume_up_outlined,
              color: AppColors.textMain,
              size: 24,
            ),
            onPressed: () {
              // TODO: TTS 토글
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) return _buildWelcomeScreen();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Image.asset('assets/images/leo_default.png', width: 96, height: 96),
          const SizedBox(height: 20),
          Text(
            '${widget.nickname}${_vocativeParticle(widget.nickname)}, 안녕! 👋\n오늘 어떤 이야기를 해볼까?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          ..._quickReplies.map((r) => _buildQuickReplyButton(r.$1, r.$2)),
        ],
      ),
    );
  }

  Widget _buildQuickReplyButton(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _sendQuickReply(text),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.textMain : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isUser ? Colors.white : AppColors.textMain,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: _isTranscribing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? AppColors.primary : AppColors.textSub,
                    size: 26,
                  ),
            onPressed: _toggleListening,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                decoration: const InputDecoration(
                  hintText: '레오에게 말해봐...',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textSub),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    final activeSession = _sessions.firstWhere(
      (s) => s.id == _activeSessionId,
      orElse: () => _sessions.first,
    );
    final pastSessions = _sessions
        .where((s) => s.id != _activeSessionId)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: AppColors.textMain,
                    size: 24,
                  ),
                  onPressed: () => setState(() {
                    _isHistoryOpen = false;
                    _isSessionsExpanded = false;
                  }),
                ),
                const Text(
                  '대화 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: BE 연동 시 새 세션 생성 API 호출
                  setState(() {
                    _messages = [];
                    _isHistoryOpen = false;
                    _isSessionsExpanded = false;
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  '새로운 대화 시작',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () =>
                  setState(() => _isSessionsExpanded = !_isSessionsExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textMain,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        activeSession.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isSessionsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: _isSessionsExpanded && pastSessions.isNotEmpty
                  ? Column(
                      children: [
                        const SizedBox(height: 12),
                        ...pastSessions.map(
                          (session) => GestureDetector(
                            onTap: () {
                              // TODO: BE 연동 시 _mockMessagesForSession을 실제 API 로드로 교체
                              setState(() {
                                _activeSessionId = session.id;
                                _messages = _mockMessagesForSession(session.id);
                                _isHistoryOpen = false;
                                _isSessionsExpanded = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      session.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSub,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
