import 'home_model.dart';

class TodoItem {
  final String? id;
  final String title;
  final String emoji;
  final int estimatedMinutes;
  bool isCompleted;
  final int? targetTabIndex;
  final LearningType? learningType;
  final TodoSource _source;

  bool get isUserCreated => _source == TodoSource.USER;
  bool get canDelete =>
      _source == TodoSource.USER || _source == TodoSource.AGENT;

  TodoItem({
    this.id,
    required this.title,
    required this.emoji,
    required this.estimatedMinutes,
    this.isCompleted = false,
    this.targetTabIndex,
    this.learningType,
    TodoSource source = TodoSource.SYSTEM,
  }) : _source = source;

  factory TodoItem.fromResponse(TodoResponse res) {
    return TodoItem(
      id: res.id,
      title: res.title,
      emoji: _emojiForType(res.type),
      estimatedMinutes: (res.estimatedTimeSec / 60).ceil().clamp(1, 999),
      isCompleted: res.isCompleted,
      targetTabIndex: _tabIndexForType(res.type),
      learningType: res.learningType,
      source: res.source,
    );
  }

  static String _emojiForType(String type) {
    switch (type.toUpperCase()) {
      case 'CHAT':
        return '🦫';
      case 'LEARNING':
        return '📚';
      case 'EMOTION':
        return '💛';
      default:
        return '✅';
    }
  }

  static int? _tabIndexForType(String type) {
    switch (type.toUpperCase()) {
      case 'LEARNING':
        return 1;
      case 'CHAT':
        return 2;
      case 'EMOTION':
        return 3;
      default:
        return null;
    }
  }

  static List<TodoItem> generateDailyTodos() {
    return [
      TodoItem(
        title: '레오랑 인사하기',
        emoji: '🦫',
        estimatedMinutes: 1,
        targetTabIndex: 2,
      ),
      TodoItem(
        title: '오늘의 문제 3개 풀기',
        emoji: '📚',
        estimatedMinutes: 5,
        targetTabIndex: 1,
      ),
    ];
  }
}
