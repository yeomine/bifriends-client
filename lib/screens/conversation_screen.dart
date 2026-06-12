import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/member_model.dart';
import '../services/chat_service.dart';
import '../services/home_service.dart';
import '../services/member_service.dart';
import '../services/stt_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/korean_learning_roadmap.dart';
import '../widgets/learning_roadmap.dart' show LearningRoadmap;

class ConversationScreen extends StatefulWidget {
  final String? pendingTodoId;
  final VoidCallback? onTodoCompleted;

  const ConversationScreen({
    super.key,
    this.pendingTodoId,
    this.onTodoCompleted,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final HomeService _homeService = HomeService();
  final MemberService _memberService = MemberService();
  final SttService _sttService = SttService();

  String? _pendingTodoId;

  Member? _member;
  late String _sessionId;
  bool _isHistoryOpen = false;
  bool _isSessionsExpanded = false;
  bool _isListening = false;
  bool _isTranscribing = false;
  bool _isLeoTyping = false;
  bool _isSessionsLoading = false;

  List<ChatSession> _sessions = [];
  List<ChatMessage> _messages = [];

  static const List<(String, String)> _quickReplies = [
    ('🔢', '수학이 어려워'),
    ('📖', '국어 도와줘'),
    ('💬', '그냥 레오랑 이야기 나누고 싶어'),
    ('✅', '오늘 할 일 적을게'),
  ];

  @override
  void initState() {
    super.initState();
    _pendingTodoId = widget.pendingTodoId;
    _sessionId = ChatService.generateSessionId();
    _fetchMember();
    _fetchSessions();
  }

  @override
  void didUpdateWidget(ConversationScreen old) {
    super.didUpdateWidget(old);
    if (widget.pendingTodoId != null &&
        widget.pendingTodoId != old.pendingTodoId) {
      _pendingTodoId = widget.pendingTodoId;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sttService.dispose();
    super.dispose();
  }

  Future<void> _fetchMember() async {
    try {
      final member = await _memberService.getMe();
      if (mounted) setState(() => _member = member);
    } catch (_) {}
  }

  Future<void> _fetchSessions() async {
    setState(() => _isSessionsLoading = true);
    try {
      final sessions = await _chatService.getMySessions();
      if (mounted) setState(() => _sessions = sessions);
    } catch (e) {
      debugPrint('[Chat] 세션 목록 로드 오류: $e');
    } finally {
      if (mounted) setState(() => _isSessionsLoading = false);
    }
  }

  String get _welcomeGreeting {
    final name = _member?.displayNickname ?? '친구';
    return '$name${_vocativeParticle(name)}, 안녕! 👋\n오늘 어떤 이야기를 해볼까?';
  }

  ChatMessage _makeMessage(
    String idPrefix,
    String content,
    bool isUser, {
    CtaAction? cta,
    List<TodoCreated> todosCreated = const [],
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: '${idPrefix}_${now.millisecondsSinceEpoch}',
      content: content,
      isUser: isUser,
      timestamp: now,
      cta: cta,
      todosCreated: todosCreated,
    );
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLeoTyping) return;

    setState(() {
      _messages.add(_makeMessage('msg', text, true));
      _isLeoTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final chatResponse = await _chatService.sendMessage(
        sessionId: _sessionId,
        message: text,
        nickname: _member?.displayNickname ?? '친구',
        grade: _member?.displayGrade ?? 4,
        interests: _member?.interests ?? [],
      );

      if (mounted && chatResponse.reply.isNotEmpty) {
        setState(
          () => _messages.add(
            _makeMessage(
              'reply',
              chatResponse.reply,
              false,
              cta: chatResponse.cta,
              todosCreated: chatResponse.todosCreated,
            ),
          ),
        );
        if (chatResponse.todosCreated.isNotEmpty) {
          _showTodosSnackbar(chatResponse.todosCreated);
        }
      }

      // 첫 메시지 전송 성공 시 chat todo 완료 처리
      if (_pendingTodoId != null) {
        final todoId = _pendingTodoId!;
        _pendingTodoId = null;
        try {
          await _homeService.completeTodo(todoId);
        } catch (_) {}
        widget.onTodoCompleted?.call();
      }
    } catch (e) {
      debugPrint('[Chat] sendMessage 오류: $e');
      if (mounted) {
        setState(
          () => _messages.add(
            _makeMessage('err', '레오가 지금 답하기 어려워요 😅\n잠시 후 다시 말 걸어줘!', false),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLeoTyping = false);
        _scrollToBottom();
      }
    }
  }

  void _sendQuickReply(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  void _scrollToBottom() {
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

  // 받침 있으면 '아', 없으면 '야'
  String _vocativeParticle(String name) {
    if (name.isEmpty) return '야';
    final code = name.codeUnitAt(name.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return '야';
    return (code - 0xAC00) % 28 == 0 ? '야' : '아';
  }

  // ── 공통 헬퍼 ─────────────────────────────────────────────────────────────

  static const _leoBubbleDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(18),
    ),
    boxShadow: [
      BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  void _closeHistoryPanel() {
    _isHistoryOpen = false;
    _isSessionsExpanded = false;
  }

  void _pushScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmDeleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '이 대화를 지울까요? 🗑️',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        content: Text(
          '"${session.title}"\n지우면 다시 볼 수 없어요!',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSub,
            height: 1.6,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '아니요!',
              style: TextStyle(
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '네, 지울게요',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) await _deleteSession(session);
  }

  Future<void> _deleteSession(ChatSession session) async {
    try {
      await _chatService.deleteSession(session.id);
      if (!mounted) return;
      setState(() {
        _sessions.removeWhere((s) => s.id == session.id);
        if (_sessionId == session.id) {
          _sessionId = ChatService.generateSessionId();
          _messages = [];
          _isLeoTyping = false;
          _closeHistoryPanel();
        }
      });
    } catch (e) {
      debugPrint('[Chat] 세션 삭제 오류: $e');
      if (mounted) {
        AppToast.show(context, '삭제에 실패했어요. 다시 시도해줘!', isError: true);
      }
    }
  }

  Future<void> _loadSessionMessages(String sessionId) async {
    setState(() {
      _sessionId = sessionId;
      _messages = [];
      _isLeoTyping = false;
      _closeHistoryPanel();
    });
    try {
      final messages = await _chatService.getSessionMessages(sessionId);
      if (mounted) {
        setState(() => _messages = messages);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[Chat] 과거 메시지 로드 오류: $e');
    }
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
            onTap: () => setState(_closeHistoryPanel),
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
                      _sessions.isEmpty
                          ? '대화 시작하기'
                          : '${_sessions.length}개의 대화',
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
    if (_messages.isEmpty && !_isLeoTyping) return _buildWelcomeScreen();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length + (_isLeoTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLeoTyping && index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _leoBubbleDecoration,
        child: const _TypingDots(),
      ),
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
            _welcomeGreeting,
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
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isUser
            ? const BoxDecoration(
                color: AppColors.textMain,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              )
            : _leoBubbleDecoration,
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

    if (!isUser && msg.cta != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bubble,
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: _buildCtaButton(msg.cta!),
          ),
        ],
      );
    }
    return bubble;
  }

  Widget _buildCtaButton(CtaAction cta) {
    return GestureDetector(
      onTap: () => _handleCtaTap(cta),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              cta.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCtaTap(CtaAction cta) {
    final isMath = cta.subject == 'math';
    _pushScreen(
      Scaffold(
        appBar: AppBar(
          title: Text(
            isMath ? '수학 공부방' : '국어 공부방',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textMain,
          elevation: 0,
        ),
        backgroundColor: AppColors.background,
        body: isMath
            ? const LearningRoadmap()
            : const KoreanLearningRoadmap(),
      ),
    );
  }

  void _showTodosSnackbar(List<TodoCreated> todos) {
    final text = todos.length == 1
        ? '🎉  할 일 1개가 추가됐어요!'
        : '🎉  할 일 ${todos.length}개가 추가됐어요!';
    AppToast.show(context, text);
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

  Widget _buildSessionListItem(ChatSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _loadSessionMessages(session.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSub,
              size: 18,
            ),
            onPressed: () => _confirmDeleteSession(session),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    final activeSession = _sessions
        .where((s) => s.id == _sessionId)
        .firstOrNull;
    final pastSessions = _sessions.where((s) => s.id != _sessionId).toList();

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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                        onPressed: () => setState(_closeHistoryPanel),
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
                      onPressed: () => setState(() {
                        _sessionId = ChatService.generateSessionId();
                        _messages = [];
                        _isLeoTyping = false;
                        _closeHistoryPanel();
                      }),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        '새로운 대화 시작',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
                ],
              ),
            ),
            Expanded(
              child: _isSessionsLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : _sessions.isEmpty
                  ? const Center(
                      child: Text(
                        '아직 대화 기록이 없어요',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        if (activeSession != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.textMain,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _isSessionsExpanded =
                                          !_isSessionsExpanded,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
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
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteSession(activeSession),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          if (_isSessionsExpanded &&
                              pastSessions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...pastSessions.map(_buildSessionListItem),
                          ],
                        ] else
                          ...pastSessions.map(_buildSessionListItem),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _dotCount = 3;
  static const _dotSize = 7.0;
  static const _dotSpacing = 5.0;
  static const _jumpHeight = 6.0;
  // each dot starts its jump offset by this fraction of the cycle
  static const _stagger = 0.2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotOffset(int index) {
    // shift each dot's phase by _stagger; clamp to [0,1) with modulo
    final phase = (_controller.value - index * _stagger) % 1.0;
    // smooth up-and-down: sin curve over first half of cycle, 0 for second half
    if (phase < 0.5) {
      return -math.sin(phase * math.pi * 2) * _jumpHeight;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return SizedBox(
          height: _dotSize + _jumpHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < _dotCount; i++) ...[
                if (i > 0) const SizedBox(width: _dotSpacing),
                Transform.translate(
                  offset: Offset(0, _dotOffset(i)),
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
