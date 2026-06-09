// ignore: constant_identifier_names
enum GreetingType { FIRST_LOGIN, COMEBACK_SHORT, COMEBACK_LONG, STREAK }

class HomeResponse {
  final MemberSummary member;
  final GreetingResponse greeting;
  final UserStatsResponse stats;
  final AttendanceResult attendance;
  final List<TodoResponse> todos;

  HomeResponse({
    required this.member,
    required this.greeting,
    required this.stats,
    required this.attendance,
    required this.todos,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      member: MemberSummary.fromJson(json['member'] as Map<String, dynamic>),
      greeting: GreetingResponse.fromJson(
        json['greeting'] as Map<String, dynamic>,
      ),
      stats: UserStatsResponse.fromJson(json['stats'] as Map<String, dynamic>),
      attendance: AttendanceResult.fromJson(
        json['attendance'] as Map<String, dynamic>,
      ),
      todos: (json['todos'] as List<dynamic>)
          .map((e) => TodoResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MemberSummary {
  final String nickname;

  MemberSummary({required this.nickname});

  factory MemberSummary.fromJson(Map<String, dynamic> json) {
    return MemberSummary(nickname: json['nickname'] as String? ?? '친구');
  }
}

class GreetingResponse {
  final GreetingType type;
  final int streakDays;
  final String message;

  GreetingResponse({
    required this.type,
    required this.streakDays,
    required this.message,
  });

  factory GreetingResponse.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'STREAK';
    final type = GreetingType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => GreetingType.STREAK,
    );
    return GreetingResponse(
      type: type,
      streakDays: json['streakDays'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

class UserStatsResponse {
  final int level;
  final int availablePool;
  final int totalPoolEarned;
  final int streakDays;
  final int currentLevelProgress;
  final int totalPoolForCurrentLevelUp;
  final int poolNeededForNextLevel;

  UserStatsResponse({
    required this.level,
    required this.availablePool,
    required this.totalPoolEarned,
    required this.streakDays,
    required this.currentLevelProgress,
    required this.totalPoolForCurrentLevelUp,
    required this.poolNeededForNextLevel,
  });

  factory UserStatsResponse.fromJson(Map<String, dynamic> json) {
    return UserStatsResponse(
      level: json['level'] as int? ?? 1,
      availablePool: json['availablePool'] as int? ?? 0,
      totalPoolEarned: json['totalPoolEarned'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      currentLevelProgress: json['currentLevelProgress'] as int? ?? 0,
      totalPoolForCurrentLevelUp:
          json['totalPoolForCurrentLevelUp'] as int? ?? 1000,
      poolNeededForNextLevel: json['poolNeededForNextLevel'] as int? ?? 1000,
    );
  }
}

class RewardResult {
  final int earnedPool;
  final int availablePool;
  final int totalPoolEarned;
  final int levelBefore;
  final int levelAfter;

  bool get leveledUp => levelAfter > levelBefore;

  RewardResult({
    required this.earnedPool,
    required this.availablePool,
    required this.totalPoolEarned,
    required this.levelBefore,
    required this.levelAfter,
  });

  factory RewardResult.fromJson(Map<String, dynamic> json) {
    return RewardResult(
      earnedPool: json['earnedPool'] as int? ?? 0,
      availablePool: json['availablePool'] as int? ?? 0,
      totalPoolEarned: json['totalPoolEarned'] as int? ?? 0,
      levelBefore: json['levelBefore'] as int? ?? 1,
      levelAfter: json['levelAfter'] as int? ?? 1,
    );
  }
}

class AttendanceResult {
  final bool isFirstAttendanceToday;
  final int streakDays;
  final RewardResult? reward;

  AttendanceResult({
    required this.isFirstAttendanceToday,
    required this.streakDays,
    this.reward,
  });

  factory AttendanceResult.fromJson(Map<String, dynamic> json) {
    return AttendanceResult(
      isFirstAttendanceToday: json['isFirstAttendanceToday'] as bool? ?? false,
      streakDays: json['streakDays'] as int? ?? 0,
      reward: json['reward'] != null
          ? RewardResult.fromJson(json['reward'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ignore: constant_identifier_names
enum TodoStatus { PENDING, IN_PROGRESS, COMPLETED }

// ignore: constant_identifier_names
enum TodoSource { SYSTEM, AGENT, USER }

// ignore: constant_identifier_names
enum LearningType { MATH, LANGUAGE }

class TodoResponse {
  final String id;
  final String type;
  final String title;
  final TodoStatus status;
  final TodoSource source;
  final LearningType? learningType;
  final String assignedDate;

  bool get isCompleted => status == TodoStatus.COMPLETED;

  TodoResponse({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.source,
    this.learningType,
    required this.assignedDate,
  });

  factory TodoResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'PENDING';
    final status = TodoStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => TodoStatus.PENDING,
    );

    final sourceStr = json['source'] as String? ?? 'SYSTEM';
    final source = TodoSource.values.firstWhere(
      (e) => e.name == sourceStr,
      orElse: () => TodoSource.SYSTEM,
    );

    final learningTypeStr = json['learningType'] as String?;
    final learningType = learningTypeStr != null
        ? LearningType.values.firstWhere(
            (e) => e.name == learningTypeStr,
            orElse: () => LearningType.LANGUAGE,
          )
        : null;

    return TodoResponse(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: status,
      source: source,
      learningType: learningType,
      assignedDate: json['assignedDate'] as String? ?? '',
    );
  }
}

class TodoCompleteResult {
  final TodoResponse todo;
  final RewardResult singleReward;
  final RewardResult? allCompleteBonus;

  bool get leveledUp =>
      singleReward.leveledUp || (allCompleteBonus?.leveledUp == true);

  TodoCompleteResult({
    required this.todo,
    required this.singleReward,
    this.allCompleteBonus,
  });

  factory TodoCompleteResult.fromJson(Map<String, dynamic> json) {
    return TodoCompleteResult(
      todo: TodoResponse.fromJson(json['todo'] as Map<String, dynamic>),
      singleReward: RewardResult.fromJson(
        json['singleReward'] as Map<String, dynamic>,
      ),
      allCompleteBonus: json['allCompleteBonus'] != null
          ? RewardResult.fromJson(
              json['allCompleteBonus'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
