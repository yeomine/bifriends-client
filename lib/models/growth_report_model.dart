import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

  static ChatSafetyLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'green':
        return ChatSafetyLevel.green;
      case 'yellow':
        return ChatSafetyLevel.yellow;
      case 'red':
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

class ChatSafetySignal {
  final ChatSafetyLevel level;
  final String description;

  const ChatSafetySignal({required this.level, required this.description});

  factory ChatSafetySignal.fromJson(Map<String, dynamic> json) {
    return ChatSafetySignal(
      level: ChatSafetyLevelExt.fromString(json['level'] as String),
      description: json['description'] as String,
    );
  }
}

enum SubjectType { korean, math, social }

extension SubjectTypeExt on SubjectType {
  IconData get icon {
    switch (this) {
      case SubjectType.korean:
        return Icons.menu_book;
      case SubjectType.math:
        return Icons.gps_fixed;
      case SubjectType.social:
        return Icons.people_alt_outlined;
    }
  }

  Color get color {
    switch (this) {
      case SubjectType.korean:
        return const Color(0xFF5B9BD5);
      case SubjectType.math:
        return const Color(0xFFE07070);
      case SubjectType.social:
        return AppColors.textSub;
    }
  }

  static SubjectType fromString(String value) {
    switch (value) {
      case 'korean':
        return SubjectType.korean;
      case 'math':
        return SubjectType.math;
      case 'social':
        return SubjectType.social;
      default:
        return SubjectType.korean;
    }
  }
}

class SubjectReport {
  final String name;
  final SubjectType type;
  final String goodPoint;
  final String? hardPoint;

  const SubjectReport({
    required this.name,
    required this.type,
    required this.goodPoint,
    this.hardPoint,
  });

  factory SubjectReport.fromJson(Map<String, dynamic> json) {
    return SubjectReport(
      name: json['name'] as String,
      type: SubjectTypeExt.fromString(json['type'] as String),
      goodPoint: json['goodPoint'] as String,
      hardPoint: json['hardPoint'] as String?,
    );
  }
}

class LearningPattern {
  final List<String> studyDays;
  final int totalStudyCount;

  const LearningPattern({
    required this.studyDays,
    required this.totalStudyCount,
  });

  factory LearningPattern.fromJson(Map<String, dynamic> json) {
    return LearningPattern(
      studyDays: List<String>.from(json['studyDays'] as List),
      totalStudyCount: json['totalStudyCount'] as int,
    );
  }
}

class GrowthReport {
  final String childName;
  final String weekRange;
  final String summary;
  final LearningPattern pattern;
  final List<SubjectReport> subjects;
  final ChatSafetySignal? chatSafetySignal;

  const GrowthReport({
    required this.childName,
    required this.weekRange,
    required this.summary,
    required this.pattern,
    required this.subjects,
    this.chatSafetySignal,
  });

  factory GrowthReport.fromJson(Map<String, dynamic> json) {
    final safetyJson = json['chatSafetySignal'] as Map<String, dynamic>?;
    return GrowthReport(
      childName: json['childName'] as String,
      weekRange: json['weekRange'] as String,
      summary: json['summary'] as String,
      pattern: LearningPattern.fromJson(
        json['learningPattern'] as Map<String, dynamic>,
      ),
      subjects: (json['subjects'] as List)
          .map((s) => SubjectReport.fromJson(s as Map<String, dynamic>))
          .toList(),
      chatSafetySignal:
          safetyJson != null ? ChatSafetySignal.fromJson(safetyJson) : null,
    );
  }

  static GrowthReport mock() => mockHistory().first;

  static List<GrowthReport> mockHistory() => const [
    GrowthReport(
      childName: '정우치치',
      weekRange: '5월 17일 ~ 5월 23일',
      summary:
          '이번 주 정우치치는 수학에서 눈에 띄는 성장을 보여줬어요. '
          '더하기 개념을 꾸준히 연습하며 자신감이 붙었고, 국어 독해에서도 이야기의 흐름을 파악하는 능력이 향상되었습니다. '
          '스스로 문제를 풀어보려는 태도가 정말 훌륭했어요!',
      pattern: LearningPattern(
        studyDays: ['월', '화', '수', '금', '토'],
        totalStudyCount: 15,
      ),
      subjects: [
        SubjectReport(
          name: '국어',
          type: SubjectType.korean,
          goodPoint: '비 오는 날 학습을 통해 감각적 표현을 익히고 문장을 완성하는 능력이 향상되었어요.',
          hardPoint: '더 다양한 어휘를 접할 수 있도록 독서를 권장해 주세요.',
        ),
        SubjectReport(
          name: '수학',
          type: SubjectType.math,
          goodPoint: '더하기 개념을 완벽히 이해하고 빠르게 계산하는 연습을 잘 해내고 있어요.',
          hardPoint: null,
        ),
      ],
      chatSafetySignal: ChatSafetySignal(
        level: ChatSafetyLevel.green,
        description:
            '정우치치는 자신의 감정을 인지하고 조절하려는 의지가 강하며, 정서적으로 매우 안정된 상태에서 학습에 참여하고 있습니다.',
      ),
    ),
    GrowthReport(
      childName: '정우치치',
      weekRange: '5월 10일 ~ 5월 16일',
      summary:
          '정우치치가 이번 주에는 새로운 개념 학습에 도전하며 많은 노력을 기울였어요. '
          '어려운 문제에도 포기하지 않고 끝까지 해결하려는 모습이 인상적이었습니다.',
      pattern: LearningPattern(
        studyDays: ['월', '수', '목', '토'],
        totalStudyCount: 10,
      ),
      subjects: [
        SubjectReport(
          name: '국어',
          type: SubjectType.korean,
          goodPoint: '낱말 카드 학습을 통해 새로운 어휘를 착실히 쌓아가고 있어요.',
          hardPoint: '문장 전체의 의미를 파악하는 연습이 더 필요해요.',
        ),
        SubjectReport(
          name: '수학',
          type: SubjectType.math,
          goodPoint: '도형 알기 단계를 완료하고 세모, 네모, 동그라미를 완벽하게 구분할 수 있게 되었어요.',
          hardPoint: '집중 시간을 조금 더 늘려보면 좋겠어요.',
        ),
      ],
      chatSafetySignal: ChatSafetySignal(
        level: ChatSafetyLevel.yellow,
        description:
            '정우치치는 대체로 안정적이지만, 이번 주 일부 활동에서 집중력이 흔들리는 모습이 관찰되었어요. 가벼운 대화로 기분을 확인해 주세요.',
      ),
    ),
    GrowthReport(
      childName: '정우치치',
      weekRange: '5월 3일 ~ 5월 9일',
      summary:
          '꾸준한 학습 습관이 결실을 맺고 있어요. '
          '정우치치는 매일 조금씩 성장하며 학습에 대한 흥미를 높여가고 있습니다.',
      pattern: LearningPattern(studyDays: ['화', '수', '금'], totalStudyCount: 7),
      subjects: [
        SubjectReport(
          name: '국어',
          type: SubjectType.korean,
          goodPoint: '국어 1단계를 시작하며 첫 이야기를 즐겁게 읽어나가고 있어요.',
          hardPoint: null,
        ),
        SubjectReport(
          name: '수학',
          type: SubjectType.math,
          goodPoint: '숫자 세기 1단계를 마쳤어요! 1부터 10까지 자신있게 셀 수 있게 되었습니다.',
          hardPoint: null,
        ),
      ],
      chatSafetySignal: ChatSafetySignal(
        level: ChatSafetyLevel.green,
        description:
            '정우치치는 챗봇과의 대화에서 긍정적인 감정 표현이 많았고, 학습 전반에 걸쳐 안정된 심리 상태를 유지하고 있습니다.',
      ),
    ),
    GrowthReport(
      childName: '정우치치',
      weekRange: '4월 26일 ~ 5월 2일',
      summary:
          '이번 한 주 동안 정우치치는 자신의 감정을 들여다보고 솔직하게 표현하는 법을 배우며 마음의 키가 쑥쑥 자랐어요. '
          '분노와 두려움이라는 어려운 감정을 만났을 때, 어떻게 마음을 다스리고 도움을 요청해야 하는지 진지하게 고민하는 모습이 참 기특했답니다. '
          '비록 모든 활동을 다 완료하지는 못했지만, 매 순간 최선을 다해 참여하며 성장해 나가는 정우치치를 함께 응원해 주세요!',
      pattern: LearningPattern(
        studyDays: ['월', '화', '목', '토'],
        totalStudyCount: 12,
      ),
      subjects: [
        SubjectReport(
          name: '국어',
          type: SubjectType.korean,
          goodPoint: '국어 1단계 학습을 시작하며 한글과 친해지는 과정을 차근차근 밟아나가고 있어요.',
          hardPoint: '학습 빈도를 조금 더 높여서 꾸준히 문장을 읽고 이해하는 연습이 필요해 보여요.',
        ),
        SubjectReport(
          name: '수학',
          type: SubjectType.math,
          goodPoint: '매일 주어지는 \'오늘의 문제\' 풀이에 도전하며 수학적 사고력을 기르고 있습니다.',
          hardPoint: '어려운 문제가 나와도 포기하지 않고 끝까지 문제를 해결하려는 끈기가 조금 더 필요해요.',
        ),
        SubjectReport(
          name: '관계 시나리오',
          type: SubjectType.social,
          goodPoint:
              '\'머리끝까지 화가 난다\', \'심장이 콩닥콩닥\' 같은 풍부한 감정 표현을 익히고, '
              '화가 날 때 숨을 깊게 마시는 건강한 대처법을 잘 이해하고 있어요.',
          hardPoint: null,
        ),
      ],
      chatSafetySignal: ChatSafetySignal(
        level: ChatSafetyLevel.red,
        description:
            '이번 주 정우치치가 부정적인 감정 표현을 반복하는 패턴이 감지되었어요. 학교나 친구 관계에서 어려움이 있는지 따뜻하게 여쭤봐 주세요.',
      ),
    ),
  ];

  // TODO: BE 연동 시 실제 최신 주차 데이터로 교체
  static GrowthReport mockLatest() => const GrowthReport(
    childName: '정우치치',
    weekRange: '5월 24일 ~ 5월 30일',
    summary:
        '이번 주도 정우치치는 꾸준히 학습에 참여하고 있어요! '
        '새로운 도전을 이어가며 성장하는 모습을 확인해보세요.',
    pattern: LearningPattern(studyDays: ['월', '화', '수'], totalStudyCount: 5),
    subjects: [
      SubjectReport(
        name: '국어',
        type: SubjectType.korean,
        goodPoint: '새로운 단원을 시작하며 적극적으로 참여하고 있어요.',
        hardPoint: null,
      ),
      SubjectReport(
        name: '수학',
        type: SubjectType.math,
        goodPoint: '이번 주 수학 학습을 꾸준히 이어가고 있습니다.',
        hardPoint: null,
      ),
    ],
    chatSafetySignal: ChatSafetySignal(
      level: ChatSafetyLevel.green,
      description:
          '정우치치는 자신의 감정을 인지하고 조절하려는 의지가 강하며, 정서적으로 매우 안정된 상태에서 학습에 참여하고 있습니다.',
    ),
  );
}
