import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'guardian_mission_model.dart';

enum ChatSafetyLevel { green, yellow, red }

extension ChatSafetyLevelExt on ChatSafetyLevel {
  String get label {
    switch (this) {
      case ChatSafetyLevel.green:
        return 'Green';
      case ChatSafetyLevel.yellow:
        return 'Yellow';
      case ChatSafetyLevel.red:
        return 'Red';
    }
  }

  String get defaultDescription {
    switch (this) {
      case ChatSafetyLevel.green:
        return '아이가 정서적으로 안정된 상태에서 학습에 참여하고 있습니다.';
      case ChatSafetyLevel.yellow:
        return '일부 활동에서 감정 기복이 관찰되었어요. 가벼운 대화로 기분을 확인해 주세요.';
      case ChatSafetyLevel.red:
        return '부정적인 감정 표현이 반복 감지되었어요. 학교나 친구 관계에서 어려움이 있는지 따뜻하게 여쭤봐 주세요.';
    }
  }

  static ChatSafetyLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'YELLOW':
        return ChatSafetyLevel.yellow;
      case 'RED':
        return ChatSafetyLevel.red;
      default:
        return ChatSafetyLevel.green;
    }
  }

  Color get color {
    switch (this) {
      case ChatSafetyLevel.green:
        return const Color(0xFF4CAF50);
      case ChatSafetyLevel.yellow:
        return const Color(0xFFFFB300);
      case ChatSafetyLevel.red:
        return const Color(0xFFE53935);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ChatSafetyLevel.green:
        return const Color(0xFFE8F5F0);
      case ChatSafetyLevel.yellow:
        return const Color(0xFFFFF8E1);
      case ChatSafetyLevel.red:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get borderColor {
    switch (this) {
      case ChatSafetyLevel.green:
        return const Color(0xFF80CBC4);
      case ChatSafetyLevel.yellow:
        return const Color(0xFFFFCC80);
      case ChatSafetyLevel.red:
        return const Color(0xFFEF9A9A);
    }
  }
}

class ReportSummary {
  final int reportId;
  final String weekStart;
  final String weekEnd;
  final ChatSafetyLevel safetySignal;
  final bool hasMission;

  const ReportSummary({
    required this.reportId,
    required this.weekStart,
    required this.weekEnd,
    required this.safetySignal,
    required this.hasMission,
  });

  String get weekRange => _formatRange(weekStart, weekEnd);

  static String _formatRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return '${s.month}월 ${s.day}일 ~ ${e.month}월 ${e.day}일';
    } catch (_) {
      return '$start ~ $end';
    }
  }

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    reportId: json['reportId'] as int,
    weekStart: json['weekStart'] as String,
    weekEnd: json['weekEnd'] as String,
    safetySignal:
        ChatSafetyLevelExt.fromString(json['safetySignal'] as String? ?? ''),
    hasMission: json['hasMission'] as bool? ?? false,
  );
}

class GrowthSection {
  final String summary;
  final String? parentTip;

  const GrowthSection({required this.summary, this.parentTip});

  factory GrowthSection.fromJson(Map<String, dynamic> json) => GrowthSection(
    summary: json['summary'] as String? ?? '',
    parentTip: json['parentTip'] as String?,
  );
}

class LearningPattern {
  final List<int> learningDays; // 1=월 ~ 7=일 (ISO weekday)
  final int completedTodoCount;

  const LearningPattern({
    required this.learningDays,
    required this.completedTodoCount,
  });

  static const allDayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  // 1-indexed: 1=월, 7=일
  bool isDayActive(int isoWeekday) => learningDays.contains(isoWeekday);

  factory LearningPattern.fromJson(Map<String, dynamic> json) => LearningPattern(
    learningDays: (json['learningDays'] as List<dynamic>)
        .map((e) => e as int)
        .toList(),
    completedTodoCount: json['completedTodoCount'] as int? ?? 0,
  );
}

class SubjectSummary {
  final String key; // 'math', 'korean'
  final String wellDone;
  final String struggled;

  const SubjectSummary({required this.key, required this.wellDone, required this.struggled});

  String get displayName {
    switch (key) {
      case 'math': return '수학';
      case 'korean': return '국어';
      default: return key;
    }
  }

  IconData get icon {
    switch (key) {
      case 'math': return Icons.gps_fixed;
      case 'korean': return Icons.menu_book;
      default: return Icons.school_outlined;
    }
  }

  Color get color {
    switch (key) {
      case 'math': return const Color(0xFFE07070);
      case 'korean': return const Color(0xFF5B9BD5);
      default: return AppColors.textSub;
    }
  }
}

class LearningStatus {
  final SubjectSummary math;
  final SubjectSummary korean;

  const LearningStatus({required this.math, required this.korean});

  List<SubjectSummary> get all => [korean, math];

  factory LearningStatus.fromJson(Map<String, dynamic> json) {
    SubjectSummary parse(String key) {
      final m = json[key] as Map<String, dynamic>?;
      return SubjectSummary(
        key: key,
        wellDone: m?['well_done'] as String? ?? '',
        struggled: m?['struggled'] as String? ?? '',
      );
    }
    return LearningStatus(math: parse('math'), korean: parse('korean'));
  }
}

class ChatSafetyDetail {
  final ChatSafetyLevel signal;
  final int score;
  final String reasonSummary;

  const ChatSafetyDetail({
    required this.signal,
    required this.score,
    required this.reasonSummary,
  });

  factory ChatSafetyDetail.fromJson(Map<String, dynamic> json) =>
      ChatSafetyDetail(
        signal: ChatSafetyLevelExt.fromString(
          json['signal'] as String? ?? '',
        ),
        score: json['score'] as int? ?? 0,
        reasonSummary: json['reasonSummary'] as String? ?? '',
      );
}

class LearningConceptItem {
  final String concept;
  final int solved;
  final double avgAttempts;
  final double avgHints;

  const LearningConceptItem({
    required this.concept,
    required this.solved,
    required this.avgAttempts,
    required this.avgHints,
  });

  factory LearningConceptItem.fromJson(Map<String, dynamic> json) =>
      LearningConceptItem(
        concept: json['concept'] as String? ?? '',
        solved: (json['solved'] as num?)?.toInt() ?? 0,
        avgAttempts: (json['avg_attempts'] as num?)?.toDouble() ?? 0.0,
        avgHints: (json['avg_hints'] as num?)?.toDouble() ?? 0.0,
      );
}

class LearningSummaryTodos {
  final int assigned;
  final int completed;

  const LearningSummaryTodos({
    required this.assigned,
    required this.completed,
  });

  double get completionRate => assigned == 0 ? 0 : completed / assigned;

  factory LearningSummaryTodos.fromJson(Map<String, dynamic> json) =>
      LearningSummaryTodos(
        assigned: (json['assigned'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
      );
}

class LearningSummary {
  final String weekStart;
  final String weekEnd;
  final String nickname;
  final List<String> learnedExpressions;
  final List<LearningConceptItem> math;
  final List<LearningConceptItem> korean;
  final LearningSummaryTodos todos;

  const LearningSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.nickname,
    required this.learnedExpressions,
    required this.math,
    required this.korean,
    required this.todos,
  });

  String get weekRange {
    try {
      final s = DateTime.parse(weekStart);
      final e = DateTime.parse(weekEnd);
      return '${s.month}월 ${s.day}일 ~ ${e.month}월 ${e.day}일';
    } catch (_) {
      return '$weekStart ~ $weekEnd';
    }
  }

  bool get isEmpty =>
      learnedExpressions.isEmpty && math.isEmpty && korean.isEmpty;

  factory LearningSummary.fromJson(Map<String, dynamic> json) =>
      LearningSummary(
        weekStart: json['weekStart'] as String? ?? '',
        weekEnd: json['weekEnd'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        learnedExpressions: (json['learnedExpressions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        math: (json['math'] as List<dynamic>?)
                ?.map(
                  (e) =>
                      LearningConceptItem.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        korean: (json['korean'] as List<dynamic>?)
                ?.map(
                  (e) =>
                      LearningConceptItem.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        todos: LearningSummaryTodos.fromJson(
          json['todos'] as Map<String, dynamic>? ?? {},
        ),
      );
}

class ReportDetail {
  final int reportId;
  final String weekStart;
  final String weekEnd;
  final GrowthSection growth;
  final LearningPattern learningPattern;
  final LearningStatus learningStatus;
  final ChatSafetyDetail? chatSafety;
  final GuardianMission? parentMission;
  final List<String> keywords;

  const ReportDetail({
    required this.reportId,
    required this.weekStart,
    required this.weekEnd,
    required this.growth,
    required this.learningPattern,
    required this.learningStatus,
    this.chatSafety,
    this.parentMission,
    this.keywords = const [],
  });

  String get weekRange => ReportSummary._formatRange(weekStart, weekEnd);

  factory ReportDetail.fromJson(Map<String, dynamic> json) {
    final safetyJson = json['chatSafety'] as Map<String, dynamic>?;
    final missionJson = json['parentMission'] as Map<String, dynamic>?;
    return ReportDetail(
      reportId: json['reportId'] as int,
      weekStart: json['weekStart'] as String,
      weekEnd: json['weekEnd'] as String,
      growth: GrowthSection.fromJson(json['growth'] as Map<String, dynamic>),
      learningPattern: LearningPattern.fromJson(
        json['learningPattern'] as Map<String, dynamic>,
      ),
      learningStatus: LearningStatus.fromJson(
        json['learningStatus'] as Map<String, dynamic>,
      ),
      chatSafety:
          safetyJson != null ? ChatSafetyDetail.fromJson(safetyJson) : null,
      parentMission:
          missionJson != null ? GuardianMission.fromJson(missionJson) : null,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

}
