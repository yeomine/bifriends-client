class CtaAction {
  final String type;
  final String label;
  final int? stepId;
  final int? cycleNumber;
  final String subject;

  const CtaAction({
    required this.type,
    required this.label,
    this.stepId,
    this.cycleNumber,
    required this.subject,
  });

  static CtaAction? fromJson(Map<String, dynamic>? json) {
    if (json == null || json['type'] == null) return null;
    return CtaAction(
      type: json['type'] as String,
      label: json['label'] as String? ?? '',
      stepId: json['step_id'] as int?,
      cycleNumber: json['cycle_number'] as int?,
      subject: json['subject'] as String? ?? '',
    );
  }
}

class TodoCreated {
  final String title;
  final String assignedDate;

  const TodoCreated({required this.title, required this.assignedDate});

  factory TodoCreated.fromJson(Map<String, dynamic> json) => TodoCreated(
    title: json['title'] as String,
    assignedDate: json['assigned_date'] as String,
  );
}

class ChatResponse {
  final String sessionId;
  final String reply;
  final CtaAction? cta;
  final List<int> todosCreated;

  const ChatResponse({
    required this.sessionId,
    required this.reply,
    this.cta,
    this.todosCreated = const [],
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawTodos = json['todosCreated'] as List<dynamic>?;
    return ChatResponse(
      sessionId: json['sessionId'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      cta: CtaAction.fromJson(json['cta'] as Map<String, dynamic>?),
      todosCreated: rawTodos
              ?.map((e) => e is int ? e : (e as Map<String, dynamic>)['id'] as int)
              .toList() ??
          [],
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final CtaAction? cta;
  final List<int> todosCreated;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.cta,
    this.todosCreated = const [],
  });
}

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
