// ── Rich text types ───────────────────────────────────────────────────────────

sealed class RichSpan {
  const RichSpan();
}

class PlainSpan extends RichSpan {
  final String value;
  const PlainSpan(this.value);
}

class FractionSpan extends RichSpan {
  final int numerator;
  final int denominator;
  const FractionSpan({required this.numerator, required this.denominator});
}

/// A fraction value used for options and answers in grade 6+ content.
class FractionValue {
  final int numerator;
  final int denominator;
  final String? unit;

  const FractionValue({
    required this.numerator,
    required this.denominator,
    this.unit,
  });

  /// String key used for answer matching (e.g. "2/3").
  String get key => '$numerator/$denominator';

  factory FractionValue.fromJson(Map<String, dynamic> json) => FractionValue(
        numerator: json['numerator'] as int,
        denominator: json['denominator'] as int,
        unit: json['unit'] as String?,
      );
}

// Parses a JSON `text` field — either a plain String or a List of segments.
List<RichSpan> _parseSpans(dynamic raw) {
  if (raw is String) return [PlainSpan(raw)];
  return (raw as List).map<RichSpan>((seg) {
    if (seg is String) return PlainSpan(seg);
    final m = seg as Map<String, dynamic>;
    if (m['type'] == 'fraction') {
      return FractionSpan(
          numerator: m['numerator'] as int, denominator: m['denominator'] as int);
    }
    return PlainSpan(m['value'] as String);
  }).toList();
}

// Flattens spans to a plain string for backward-compat.
String _spansToString(List<RichSpan> spans) => spans.map((s) {
      if (s is PlainSpan) return s.value;
      final f = s as FractionSpan;
      return '${f.numerator}/${f.denominator}';
    }).join('');

// ── Learning models ───────────────────────────────────────────────────────────

enum CycleType { concept, wordCard, choice, shortAnswer }

class ConceptSlide {
  final String image;
  final String text;
  final List<RichSpan>? richText;
  final String confirmButtonText;

  const ConceptSlide({
    required this.image,
    required this.text,
    this.richText,
    required this.confirmButtonText,
  });

  /// Always returns a renderable span list (falls back to plain string).
  List<RichSpan> get spans => richText ?? [PlainSpan(text)];

  factory ConceptSlide.fromJson(Map<String, dynamic> json) {
    // 'description' (국어 word_card) 또는 'text' (수학 concept) 둘 다 허용
    final raw = json['description'] ?? json['text'];
    final rich = _parseSpans(raw ?? '');
    return ConceptSlide(
      image: json['image'] as String? ?? '',
      text: _spansToString(rich),
      richText: rich,
      confirmButtonText: json['confirm_button_text'] as String? ?? '다음',
    );
  }
}

class ChoiceQuestion {
  final String questionText;
  final List<RichSpan>? richQuestionText;
  final List<String> options;
  final List<FractionValue>? fractionOptions;
  final String? answer;                 // null when fetched from API (server strips it)
  final FractionValue? fractionAnswer;  // set when answer is a fraction
  final List<String> hints;
  final List<List<RichSpan>>? richHints;
  final String? explanation;            // null when fetched from API
  final List<RichSpan>? richExplanation;
  final int difficulty;

  const ChoiceQuestion({
    required this.questionText,
    this.richQuestionText,
    required this.options,
    this.fractionOptions,
    this.answer,
    this.fractionAnswer,
    required this.hints,
    this.richHints,
    this.explanation,
    this.richExplanation,
    required this.difficulty,
  });

  List<RichSpan> get questionSpans => richQuestionText ?? [PlainSpan(questionText)];
  List<List<RichSpan>> get hintSpans =>
      richHints ?? hints.map((h) => <RichSpan>[PlainSpan(h)]).toList();
  List<RichSpan> get explanationSpans =>
      richExplanation ?? [PlainSpan(explanation ?? '')];

  factory ChoiceQuestion.fromJson(Map<String, dynamic> json) {
    // Question text (may be a List of segments in grade 6 format)
    final rich = _parseSpans(json['text'] ?? json['question_text'] ?? '');

    // Options: List<String> (grade 3) or List<{display, numerator, ...}> (grade 6)
    final rawOptions = (json['options'] as List?) ?? [];
    List<FractionValue>? fracOpts;
    List<String> strOpts;
    if (rawOptions.isNotEmpty && rawOptions.first is Map) {
      fracOpts = rawOptions
          .cast<Map<String, dynamic>>()
          .map(FractionValue.fromJson)
          .toList();
      strOpts = fracOpts.map((f) => f.key).toList();
    } else {
      strOpts = rawOptions.cast<String>();
    }

    // Answer: nullable — server strips it from API responses
    final rawAnswer = json['answer'];
    FractionValue? fracAns;
    String? strAnswer;
    if (rawAnswer is Map<String, dynamic>) {
      fracAns = FractionValue.fromJson(rawAnswer);
      strAnswer = fracAns.key;
    } else if (rawAnswer != null) {
      strAnswer = rawAnswer as String;
    }

    // Hints: List<String> (grade 3) or List<List<segment>> (grade 6)
    final rawHints = json['hint'] as List? ?? json['hints'] as List? ?? [];
    List<List<RichSpan>>? richH;
    List<String> strH;
    if (rawHints.isNotEmpty && rawHints.first is List) {
      richH = rawHints.map((h) => _parseSpans(h)).toList();
      strH = richH.map(_spansToString).toList();
    } else {
      strH = rawHints.cast<String>();
    }

    // Explanation: String (grade 3) or List<segment> (grade 6) or null (API response)
    final rawExp = json['explanation'];
    List<RichSpan>? richExp;
    String? strExp;
    if (rawExp is List) {
      richExp = _parseSpans(rawExp);
      strExp = _spansToString(richExp);
    } else if (rawExp != null) {
      strExp = rawExp as String;
    }

    return ChoiceQuestion(
      questionText: _spansToString(rich),
      richQuestionText: rich,
      options: strOpts,
      fractionOptions: fracOpts,
      answer: strAnswer,
      fractionAnswer: fracAns,
      hints: strH,
      richHints: richH,
      explanation: strExp,
      richExplanation: richExp,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }
}

class ShortAnswerQuestion {
  final String questionText;
  final List<RichSpan>? richQuestionText;
  final String? answer;                 // null when fetched from API (server strips it)
  final FractionValue? fractionAnswer;  // set when answer is a fraction
  final List<String> hints;
  final List<List<RichSpan>>? richHints;
  final String? explanation;            // null when fetched from API
  final List<RichSpan>? richExplanation;
  final int difficulty;

  const ShortAnswerQuestion({
    required this.questionText,
    this.richQuestionText,
    this.answer,
    this.fractionAnswer,
    required this.hints,
    this.richHints,
    this.explanation,
    this.richExplanation,
    required this.difficulty,
  });

  List<RichSpan> get questionSpans => richQuestionText ?? [PlainSpan(questionText)];
  List<List<RichSpan>> get hintSpans =>
      richHints ?? hints.map((h) => <RichSpan>[PlainSpan(h)]).toList();

  factory ShortAnswerQuestion.fromJson(Map<String, dynamic> json) {
    final rich = _parseSpans(json['text'] ?? json['question_text'] ?? '');

    final rawAnswer = json['answer'];
    FractionValue? fracAns;
    String? strAnswer;
    if (rawAnswer is Map<String, dynamic>) {
      fracAns = FractionValue.fromJson(rawAnswer);
      strAnswer = fracAns.key;
    } else if (rawAnswer != null) {
      strAnswer = rawAnswer as String;
    }

    final rawHints = json['hint'] as List? ?? json['hints'] as List? ?? [];
    List<List<RichSpan>>? richH;
    List<String> strH;
    if (rawHints.isNotEmpty && rawHints.first is List) {
      richH = rawHints.map((h) => _parseSpans(h)).toList();
      strH = richH.map(_spansToString).toList();
    } else {
      strH = rawHints.cast<String>();
    }

    final rawExp = json['explanation'];
    List<RichSpan>? richExp;
    String? strExp;
    if (rawExp is List) {
      richExp = _parseSpans(rawExp);
      strExp = _spansToString(richExp);
    } else if (rawExp != null) {
      strExp = rawExp as String;
    }

    return ShortAnswerQuestion(
      questionText: _spansToString(rich),
      richQuestionText: rich,
      answer: strAnswer,
      fractionAnswer: fracAns,
      hints: strH,
      richHints: richH,
      explanation: strExp,
      richExplanation: richExp,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }
}

class LearningCycle {
  final String cycleId;
  final CycleType type;
  final List<ConceptSlide>? slides;
  final List<ChoiceQuestion>? choiceQuestions;
  final List<ShortAnswerQuestion>? shortAnswerQuestions;

  const LearningCycle({
    required this.cycleId,
    required this.type,
    this.slides,
    this.choiceQuestions,
    this.shortAnswerQuestions,
  });

  int get questionCount =>
      slides?.length ??
      choiceQuestions?.length ??
      shortAnswerQuestions?.length ??
      0;

  factory LearningCycle.fromJson(Map<String, dynamic> json) {
    final CycleType type;
    // 'cycle_type' (수학) 또는 'type' (국어) 둘 다 허용
    final typeStr = json['cycle_type'] as String? ?? json['type'] as String? ?? 'concept';
    switch (typeStr) {
      case 'concept':
        type = CycleType.concept;
        break;
      case 'word_card':
        type = CycleType.wordCard;
        break;
      case 'choice':
        type = CycleType.choice;
        break;
      case 'short_answer':
        type = CycleType.shortAnswer;
        break;
      // 국어 전용 타입
      case 'fact_check':
      case 'inference':
      case 'diagram_order':
        type = CycleType.choice;
        break;
      case 'summary_fill':
        type = CycleType.choice;
        break;
      default:
        type = CycleType.concept;
    }
    // 'cycle_id' → 'cycle_number' (수학) → 'cycle' (국어) 순서로 탐색
    final cycleId = json['cycle_id'] as String? ??
        'cycle_${json['cycle_number'] ?? json['cycle']}';
    final isSlideType =
        type == CycleType.concept || type == CycleType.wordCard;
    return LearningCycle(
      cycleId: cycleId,
      type: type,
      slides: isSlideType
          ? (json['slides'] as List? ?? [])
              .map((s) => ConceptSlide.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      choiceQuestions: type == CycleType.choice
          ? (json['questions'] as List)
              .map((q) => ChoiceQuestion.fromJson(q as Map<String, dynamic>))
              .toList()
          : null,
      shortAnswerQuestions: type == CycleType.shortAnswer
          ? (json['questions'] as List)
              .map((q) =>
                  ShortAnswerQuestion.fromJson(q as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class LearningStep {
  final String stepId;
  final String stepTitle;
  final String stepDescription;
  final List<LearningCycle> cycles;

  const LearningStep({
    required this.stepId,
    required this.stepTitle,
    required this.stepDescription,
    required this.cycles,
  });

  factory LearningStep.fromJson(Map<String, dynamic> json) => LearningStep(
        stepId: json['step_id'] as String,
        stepTitle: json['step_title'] as String,
        stepDescription: json['step_description'] as String? ?? '',
        cycles: (json['cycles'] as List)
            .map((c) => LearningCycle.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

// ── API response models ────────────────────────────────────────────────────

// ignore: constant_identifier_names
enum StepStatus { AVAILABLE, IN_PROGRESS, COMPLETED, LOCKED }

class StepSummaryResponse {
  final int stepId;
  final int stepNumber;
  final String stepTitle;
  final String concept;
  final StepStatus status;
  final List<int> completedCycles;

  const StepSummaryResponse({
    required this.stepId,
    required this.stepNumber,
    required this.stepTitle,
    required this.concept,
    required this.status,
    required this.completedCycles,
  });

  factory StepSummaryResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'LOCKED';
    final status = StepStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => StepStatus.LOCKED,
    );
    return StepSummaryResponse(
      stepId: json['stepId'] as int,
      stepNumber: json['stepNumber'] as int,
      stepTitle: json['stepTitle'] as String,
      concept: json['concept'] as String,
      status: status,
      completedCycles: (json['completedCycles'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
    );
  }
}

class RoadmapResponse {
  final int grade;
  final int? lastStepId;
  final List<StepSummaryResponse> steps;

  const RoadmapResponse({
    required this.grade,
    this.lastStepId,
    required this.steps,
  });

  factory RoadmapResponse.fromJson(Map<String, dynamic> json) {
    return RoadmapResponse(
      grade: json['grade'] as int,
      lastStepId: json['lastStepId'] as int?,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => StepSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Passage {
  final String? title;
  final String text;
  final String? image;

  const Passage({this.title, required this.text, this.image});

  factory Passage.fromJson(Map<String, dynamic> json) => Passage(
        title: json['title'] as String?,
        text: json['text'] as String? ?? '',
        image: json['image'] as String?,
      );
}

class StepContentResponse {
  final int stepId;
  final String stepTitle;
  final String concept;
  final int grade;
  final Passage? passage;
  final List<LearningCycle> cycles;

  const StepContentResponse({
    required this.stepId,
    required this.stepTitle,
    required this.concept,
    required this.grade,
    this.passage,
    required this.cycles,
  });

  factory StepContentResponse.fromJson(Map<String, dynamic> json) {
    final rawPassage = json['passage'] as Map<String, dynamic>?;
    return StepContentResponse(
      stepId: json['stepId'] as int,
      stepTitle: json['stepTitle'] as String,
      concept: json['concept'] as String,
      grade: json['grade'] as int,
      passage: rawPassage != null ? Passage.fromJson(rawPassage) : null,
      cycles: (json['cycles'] as List<dynamic>)
          .map((e) => LearningCycle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ValidateResponse {
  final bool correct;
  final dynamic explanation;

  const ValidateResponse({required this.correct, this.explanation});

  factory ValidateResponse.fromJson(Map<String, dynamic> json) {
    return ValidateResponse(
      correct: json['correct'] as bool,
      explanation: json['explanation'],
    );
  }
}

class CycleCompleteResponse {
  final int stepId;
  final int cycleNumber;
  final List<int> completedCycles;
  final bool isStepCompleted;

  const CycleCompleteResponse({
    required this.stepId,
    required this.cycleNumber,
    required this.completedCycles,
    required this.isStepCompleted,
  });

  factory CycleCompleteResponse.fromJson(Map<String, dynamic> json) {
    return CycleCompleteResponse(
      stepId: json['stepId'] as int,
      cycleNumber: json['cycleNumber'] as int,
      completedCycles: (json['completedCycles'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      isStepCompleted: json['isStepCompleted'] as bool,
    );
  }
}

class StepCompleteResponse {
  final int stepId;
  final bool isStepCompleted;
  final int? nextStepId;
  final StepStatus? nextStepStatus;

  const StepCompleteResponse({
    required this.stepId,
    required this.isStepCompleted,
    this.nextStepId,
    this.nextStepStatus,
  });

  factory StepCompleteResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['nextStepStatus'] as String?;
    final nextStepStatus = statusStr != null
        ? StepStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => StepStatus.AVAILABLE,
          )
        : null;
    return StepCompleteResponse(
      stepId: json['stepId'] as int,
      isStepCompleted: json['isStepCompleted'] as bool,
      nextStepId: json['nextStepId'] as int?,
      nextStepStatus: nextStepStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// Mock data — replace each entry with a real API call when BE is ready
// ---------------------------------------------------------------------------

LearningStep mockStepForLevel(int level) {
  switch (level) {
    case 1:
      return _level1Step;
    case 2:
      return _level2Step;
    case 3:
      return _level3Step;
    case 4:
      return _level4Step;
    case 5:
      return _level5Step;
    default:
      return _level1Step;
  }
}

LearningStep mockKoreanStepForLevel(int level) {
  switch (level) {
    case 1:
      return _koreanLevel1Step;
    default:
      return _koreanLevel1Step;
  }
}

// ── Level 1: 마트에서 장보기 (grade3 step1) ──────────────────────────────────

final _level1Step = LearningStep(
  stepId: 'step_1',
  stepTitle: '마트에서 장보기',
  stepDescription: '받아올림/내림 없는 세 자리 수 덧셈과 뺄셈',
  cycles: [
    // Cycle 1: concept
    LearningCycle(
      cycleId: 'math_l1_c1',
      type: CycleType.concept,
      slides: const [
        ConceptSlide(
          image: '🛒',
          text: '마트에서 230원짜리 사과, 150원짜리 우유를 샀어요. 같이 더해볼까요?',
          confirmButtonText: '확인',
        ),
        ConceptSlide(
          image: '➕',
          text: '일의 자리 0 + 0 = 0, 십의 자리 3 + 5 = 8, 백의 자리 2 + 1 = 3.\n230 + 150 = 380원이에요. 쉽죠?',
          confirmButtonText: '확인',
        ),
        ConceptSlide(
          image: '➖',
          text: '이번엔 빼볼게요. 650원을 갖고 있었는데 320원짜리 과자를 샀어요.\n650 - 320 = 330원이 남아요!',
          confirmButtonText: '시작해볼까요?',
        ),
      ],
    ),
    // Cycle 2: choice (difficulty 1)
    LearningCycle(
      cycleId: 'math_l1_c2',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '마트에서 310원짜리 빵, 240원짜리 주스를 샀어요.\n모두 얼마일까요?',
          options: ['450원', '550원', '650원'],
          answer: '550원',
          hints: ['310 + 240을 같이 해봐요!', '일의 자리부터요. 0 + 0 = 0, 십의 자리 1 + 4 = ?', '거의 다 왔어요! 310 + 240 = 5□0'],
          explanation: '잘했어요! 310 + 240 = 550원이에요.',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '마트에서 420원짜리 과자, 160원짜리 음료를 샀어요.\n모두 얼마일까요?',
          options: ['480원', '580원', '680원'],
          answer: '580원',
          hints: ['420 + 160을 같이 해봐요!', '일의 자리부터요. 0 + 0 = 0, 십의 자리 2 + 6 = ?', '거의 다 왔어요! 420 + 160 = 5□0'],
          explanation: '잘했어요! 420 + 160 = 580원이에요.',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '나에게 970원이 있었어요. 650원짜리 빵을 샀어요.\n남은 돈은 얼마일까요?',
          options: ['220원', '320원', '420원'],
          answer: '320원',
          hints: ['970 - 650을 같이 해봐요!', '일의 자리부터요. 0 - 0 = 0, 십의 자리 7 - 5 = ?', '거의 다 왔어요! 970 - 650 = 3□0'],
          explanation: '잘했어요! 970 - 650 = 320원이에요.',
          difficulty: 1,
        ),
      ],
    ),
    // Cycle 3: choice (difficulty 2)
    LearningCycle(
      cycleId: 'math_l1_c3',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '나에게 875원이 있었어요. 340원짜리 음료수를 샀어요.\n남은 돈은 얼마일까요?',
          options: ['435원', '535원', '635원'],
          answer: '535원',
          hints: ['875 - 340을 같이 해봐요!', '일의 자리부터요. 5 - 0 = 5, 십의 자리 7 - 4 = ?', '거의 다 왔어요! 875 - 340 = 5□5'],
          explanation: '잘했어요! 875 - 340 = 535원이에요.',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '마트에서 680원짜리 과자, 250원짜리 사탕을 샀어요.\n모두 얼마일까요?',
          options: ['830원', '930원', '940원'],
          answer: '930원',
          hints: ['680 + 250을 같이 해봐요!', '일의 자리부터요. 0 + 0 = 0, 십의 자리 8 + 5 = ?', '거의 다 왔어요! 680 + 250 = 9□0'],
          explanation: '잘했어요! 680 + 250 = 930원이에요.',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '나에게 875원이 있었어요. 340원짜리 주스를 샀어요.\n남은 돈은 얼마일까요?',
          options: ['425원', '525원', '535원'],
          answer: '535원',
          hints: ['875 - 340을 같이 해봐요!', '일의 자리부터요. 5 - 0 = 5, 십의 자리 7 - 4 = ?', '거의 다 왔어요! 875 - 340 = 5□5'],
          explanation: '잘했어요! 875 - 340 = 535원이에요.',
          difficulty: 2,
        ),
      ],
    ),
    // Cycle 4: choice (difficulty 3)
    LearningCycle(
      cycleId: 'math_l1_c4',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '마트에서 234원짜리 사과, 152원짜리 바나나를 샀어요.\n모두 얼마일까요?',
          options: ['386원', '396원', '486원'],
          answer: '386원',
          hints: ['234 + 152를 같이 해봐요!', '일의 자리부터요. 4 + 2 = 6, 십의 자리 3 + 5 = ?', '거의 다 왔어요! 234 + 152 = 3□6'],
          explanation: '잘했어요! 234 + 152 = 386원이에요.',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '나에게 789원이 있었어요. 354원짜리 과자를 샀어요.\n남은 돈은 얼마일까요?',
          options: ['325원', '425원', '435원'],
          answer: '435원',
          hints: ['789 - 354를 같이 해봐요!', '일의 자리부터요. 9 - 4 = 5, 십의 자리 8 - 5 = ?', '거의 다 왔어요! 789 - 354 = 4□5'],
          explanation: '잘했어요! 789 - 354 = 435원이에요.',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '나에게 563원이 있었어요. 214원짜리 음료를 샀어요.\n남은 돈은 얼마일까요?',
          options: ['349원', '359원', '369원'],
          answer: '349원',
          hints: ['563 - 214를 같이 해봐요!', '일의 자리부터요. 3 - 4 = -1, 십의 자리 6 - 1 = 5', '거의 다 왔어요! 563 - 214 = 3□9'],
          explanation: '잘했어요! 563 - 214 = 349원이에요.',
          difficulty: 3,
        ),
      ],
    ),
    // Cycle 5: short_answer (difficulty 4)
    LearningCycle(
      cycleId: 'math_l1_c5',
      type: CycleType.shortAnswer,
      shortAnswerQuestions: const [
        ShortAnswerQuestion(
          questionText: '마트에서 사과 312원, 우유 245원을 샀어요.\n모두 얼마일까요?',
          answer: '557',
          hints: ['312 + 245를 같이 해봐요!', '일의 자리부터요. 2 + 5 = 7, 십의 자리 1 + 4 = ?', '거의 다 왔어요! 312 + 245 = 5□7'],
          explanation: '잘했어요! 312 + 245 = 557원이에요.',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '마트에 896원이 있었어요. 과자 453원을 샀어요.\n남은 돈은 얼마일까요?',
          answer: '443',
          hints: ['896 - 453을 같이 해봐요!', '일의 자리부터요. 6 - 3 = 3, 십의 자리 9 - 5 = ?', '거의 다 왔어요! 896 - 453 = 4□3'],
          explanation: '잘했어요! 896 - 453 = 443원이에요.',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '마트에서 주스 471원, 빵 326원을 샀어요.\n모두 얼마일까요?',
          answer: '797',
          hints: ['471 + 326을 같이 해봐요!', '일의 자리부터요. 1 + 6 = 7, 십의 자리 7 + 2 = ?', '거의 다 왔어요! 471 + 326 = 7□7'],
          explanation: '잘했어요! 471 + 326 = 797원이에요.',
          difficulty: 4,
        ),
      ],
    ),
  ],
);

// ── Level 2: 도형 알기 ───────────────────────────────────────────────────────

final _level2Step = LearningStep(
  stepId: 'math_level_2_step_1',
  stepTitle: '도형 알기',
  stepDescription: '세모 네모 동그라미를 찾아요',
  cycles: [
    LearningCycle(
      cycleId: 'math_l2_c1',
      type: CycleType.concept,
      slides: const [
        ConceptSlide(
          image: '🔷',
          text: '도형은 선으로 이루어진 모양이에요.\n세모, 네모, 동그라미가 대표적이에요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '🔺🟦⭕',
          text: '세모(삼각형), 네모(사각형),\n동그라미(원)를 알아봐요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '🏠',
          text: '지붕은 세모, 창문은 네모,\n시계는 동그라미! 어디에나 있어요.',
          confirmButtonText: '이해했어요!',
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l2_c2',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '⭕\n이것은 무슨 도형인가요?',
          options: ['세모', '네모', '동그라미'],
          answer: '동그라미',
          hints: ['모서리가 있나요?', '둥글둥글한 모양이에요', '정답은 동그라미예요'],
          explanation: '⭕ 은 동그라미(원)예요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '🔺\n이것은 무슨 도형인가요?',
          options: ['세모', '네모', '동그라미'],
          answer: '세모',
          hints: ['모서리가 몇 개인지 세어봐요', '뾰족한 부분이 3개예요', '정답은 세모예요'],
          explanation: '🔺 은 세모(삼각형)예요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '🟦\n이것은 무슨 도형인가요?',
          options: ['세모', '네모', '동그라미'],
          answer: '네모',
          hints: ['모서리가 몇 개인지 세어봐요', '꼭짓점이 4개예요', '정답은 네모예요'],
          explanation: '🟦 은 네모(사각형)예요!',
          difficulty: 1,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l2_c3',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '모서리(꼭짓점)가\n3개인 도형은?',
          options: ['세모', '네모', '동그라미'],
          answer: '세모',
          hints: ['손가락으로 꼭짓점을 짚어봐요', '삼각형의 꼭짓점은 3개예요', '정답은 세모예요'],
          explanation: '세모(삼각형)의 꼭짓점은 3개예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '모서리(꼭짓점)가\n4개인 도형은?',
          options: ['세모', '네모', '동그라미'],
          answer: '네모',
          hints: ['사각형의 꼭짓점을 세어봐요', '네 모서리가 있어요', '정답은 네모예요'],
          explanation: '네모(사각형)의 꼭짓점은 4개예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '꼭짓점이 없는\n도형은?',
          options: ['세모', '네모', '동그라미'],
          answer: '동그라미',
          hints: ['뾰족한 부분이 있나요?', '둥글어서 꼭짓점이 없어요', '정답은 동그라미예요'],
          explanation: '동그라미(원)는 꼭짓점이 없어요!',
          difficulty: 2,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l2_c4',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '시계는 어떤 도형과\n닮았나요?',
          options: ['세모', '네모', '동그라미'],
          answer: '동그라미',
          hints: ['시계의 모양을 떠올려봐요', '둥글둥글한 모양이에요', '정답은 동그라미예요'],
          explanation: '시계는 동그라미(원) 모양이에요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '책은 어떤 도형과\n닮았나요?',
          options: ['세모', '네모', '동그라미'],
          answer: '네모',
          hints: ['책의 모양을 떠올려봐요', '네 개의 모서리가 있어요', '정답은 네모예요'],
          explanation: '책은 네모(사각형) 모양이에요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '산의 모양은 어떤\n도형과 닮았나요?',
          options: ['세모', '네모', '동그라미'],
          answer: '세모',
          hints: ['산의 모양을 떠올려봐요', '꼭대기가 뾰족해요', '정답은 세모예요'],
          explanation: '산은 세모(삼각형) 모양이에요!',
          difficulty: 2,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l2_c5',
      type: CycleType.shortAnswer,
      shortAnswerQuestions: const [
        ShortAnswerQuestion(
          questionText: '세모(삼각형)의\n꼭짓점은 몇 개인가요?',
          answer: '3',
          hints: ['꼭짓점은 뾰족한 부분이에요', '세모의 뾰족한 곳을 세어봐요', '정답은 3이에요'],
          explanation: '세모의 꼭짓점은 3개예요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '네모(사각형)의\n변은 몇 개인가요?',
          answer: '4',
          hints: ['변은 도형의 선이에요', '네모의 선을 하나씩 세어봐요', '정답은 4이에요'],
          explanation: '네모의 변은 4개예요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '동그라미(원)의\n꼭짓점은 몇 개인가요?',
          answer: '0',
          hints: ['꼭짓점은 뾰족한 부분이에요', '동그라미에 뾰족한 곳이 있나요?', '정답은 0이에요'],
          explanation: '동그라미에는 꼭짓점이 없어요! 0개예요.',
          difficulty: 4,
        ),
      ],
    ),
  ],
);

// ── Level 3: 더하기 ──────────────────────────────────────────────────────────

final _level3Step = LearningStep(
  stepId: 'math_level_3_step_1',
  stepTitle: '더하기',
  stepDescription: '합치면 몇 개가 될까요?',
  cycles: [
    LearningCycle(
      cycleId: 'math_l3_c1',
      type: CycleType.concept,
      slides: const [
        ConceptSlide(
          image: '🍎🍊',
          text: '물건을 합치면 개수가 늘어나요.\n이렇게 합치는 것을 더하기라고 해요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '➕',
          text: '더하기는 + 기호로 나타내요.\n2 + 3 = 5 이렇게 쓰면 돼요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '🤲',
          text: '사과 2개와 귤 3개를 합치면\n모두 몇 개일까요? 함께 세어봐요!',
          confirmButtonText: '이해했어요!',
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l3_c2',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '1 + 1 = ?',
          options: ['1', '2', '3'],
          answer: '2',
          hints: ['사탕 1개에 1개를 더해봐요', '손가락 1개, 1개를 더 펴봐요', '정답은 2이에요'],
          explanation: '1+1=2예요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '2 + 2 = ?',
          options: ['3', '4', '5'],
          answer: '4',
          hints: ['손가락 2개, 2개를 더 펴봐요', '2개씩 두 번이에요', '정답은 4이에요'],
          explanation: '2+2=4예요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '3 + 2 = ?',
          options: ['4', '5', '6'],
          answer: '5',
          hints: ['손가락 3개를 펴고, 2개를 더 펴봐요', '3부터 세면서 2개 더 세어봐요', '정답은 5이에요'],
          explanation: '3+2=5예요!',
          difficulty: 2,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l3_c3',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '🍪🍪 쿠키 2개에\n🍪🍪🍪 쿠키 3개를\n더하면 몇 개인가요?',
          options: ['4', '5', '6'],
          answer: '5',
          hints: ['쿠키를 모두 모아서 세어봐요', '2개에 3개를 합치면?', '정답은 5이에요'],
          explanation: '2+3=5, 쿠키가 5개예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '4 + 1 = ?',
          options: ['4', '5', '6'],
          answer: '5',
          hints: ['4에서 1개만 더 세어봐요', '4 다음 수는 무엇인가요?', '정답은 5이에요'],
          explanation: '4+1=5예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '3 + 4 = ?',
          options: ['6', '7', '8'],
          answer: '7',
          hints: ['손가락 3개, 4개를 펴봐요', '3부터 시작해서 4번 더 세어봐요', '정답은 7이에요'],
          explanation: '3+4=7예요!',
          difficulty: 3,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l3_c4',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '5 + 3 = ?',
          options: ['7', '8', '9'],
          answer: '8',
          hints: ['5에서 3번 더 세어봐요', '5, 6, 7, 8!', '정답은 8이에요'],
          explanation: '5+3=8예요!',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '6 + 2 = ?',
          options: ['7', '8', '9'],
          answer: '8',
          hints: ['6에서 2번 더 세어봐요', '6, 7, 8!', '정답은 8이에요'],
          explanation: '6+2=8예요!',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '4 + 4 = ?',
          options: ['7', '8', '9'],
          answer: '8',
          hints: ['손가락 4개, 4개를 펴봐요', '4씩 두 번이에요', '정답은 8이에요'],
          explanation: '4+4=8예요!',
          difficulty: 3,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l3_c5',
      type: CycleType.shortAnswer,
      shortAnswerQuestions: const [
        ShortAnswerQuestion(
          questionText: '🍓🍓 딸기 2개에\n🍓🍓🍓 딸기 3개를\n더하면 몇 개인가요?',
          answer: '5',
          hints: ['딸기를 모두 세어봐요', '2개 더하기 3개예요', '정답은 5이에요'],
          explanation: '2+3=5, 딸기 5개예요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '3 + 5 = ?',
          answer: '8',
          hints: ['3에서 5번 더 세어봐요', '3, 4, 5, 6, 7, 8!', '정답은 8이에요'],
          explanation: '3+5=8이에요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '🐥🐥🐥🐥 병아리 4마리에\n🐥🐥🐥🐥🐥🐥 병아리 6마리를\n더하면 몇 마리인가요?',
          answer: '10',
          hints: ['병아리를 모두 세어봐요', '4더하기 6이에요', '정답은 10이에요'],
          explanation: '4+6=10, 병아리 10마리예요!',
          difficulty: 4,
        ),
      ],
    ),
  ],
);

// ── Level 4: 빼기 ────────────────────────────────────────────────────────────

final _level4Step = LearningStep(
  stepId: 'math_level_4_step_1',
  stepTitle: '빼기',
  stepDescription: '빼면 몇 개가 남을까요?',
  cycles: [
    LearningCycle(
      cycleId: 'math_l4_c1',
      type: CycleType.concept,
      slides: const [
        ConceptSlide(
          image: '🎈',
          text: '물건이 사라지면 개수가 줄어요.\n이렇게 빼는 것을 빼기라고 해요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '➖',
          text: '빼기는 – 기호로 나타내요.\n5 – 2 = 3 이렇게 쓰면 돼요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '🍪',
          text: '쿠키 5개 중 2개를 먹었어요.\n남은 쿠키는 몇 개일까요?',
          confirmButtonText: '이해했어요!',
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l4_c2',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '3 – 1 = ?',
          options: ['1', '2', '3'],
          answer: '2',
          hints: ['3개에서 1개를 지워봐요', '3보다 1 작은 수는?', '정답은 2이에요'],
          explanation: '3-1=2예요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '5 – 2 = ?',
          options: ['2', '3', '4'],
          answer: '3',
          hints: ['손가락 5개에서 2개를 접어봐요', '5, 4, 3 — 2번 뺐어요', '정답은 3이에요'],
          explanation: '5-2=3예요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '4 – 4 = ?',
          options: ['0', '1', '2'],
          answer: '0',
          hints: ['4개에서 4개를 모두 빼면?', '다 없어졌어요!', '정답은 0이에요'],
          explanation: '4-4=0, 하나도 안 남아요!',
          difficulty: 2,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l4_c3',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '🍎🍎🍎🍎🍎 사과 5개 중\n2개를 먹었어요.\n몇 개 남았나요?',
          options: ['2', '3', '4'],
          answer: '3',
          hints: ['사과에서 2개를 지워봐요', '5에서 2를 빼봐요', '정답은 3이에요'],
          explanation: '5-2=3, 사과 3개 남아요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '7 – 3 = ?',
          options: ['3', '4', '5'],
          answer: '4',
          hints: ['7에서 3번 거꾸로 세어봐요', '7, 6, 5, 4!', '정답은 4이에요'],
          explanation: '7-3=4예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '6 – 4 = ?',
          options: ['1', '2', '3'],
          answer: '2',
          hints: ['6에서 4번 거꾸로 세어봐요', '6, 5, 4, 3, 2!', '정답은 2이에요'],
          explanation: '6-4=2예요!',
          difficulty: 2,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l4_c4',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '8 – 5 = ?',
          options: ['2', '3', '4'],
          answer: '3',
          hints: ['8에서 5번 거꾸로 세어봐요', '8, 7, 6, 5, 4, 3!', '정답은 3이에요'],
          explanation: '8-5=3이에요!',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '10 – 3 = ?',
          options: ['6', '7', '8'],
          answer: '7',
          hints: ['10에서 3번 거꾸로 세어봐요', '10, 9, 8, 7!', '정답은 7이에요'],
          explanation: '10-3=7이에요!',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '9 – 6 = ?',
          options: ['2', '3', '4'],
          answer: '3',
          hints: ['9에서 6번 거꾸로 세어봐요', '9, 8, 7, 6, 5, 4, 3!', '정답은 3이에요'],
          explanation: '9-6=3이에요!',
          difficulty: 3,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l4_c5',
      type: CycleType.shortAnswer,
      shortAnswerQuestions: const [
        ShortAnswerQuestion(
          questionText: '🌟🌟🌟🌟🌟🌟 별 6개 중\n4개가 사라졌어요.\n몇 개 남았나요?',
          answer: '2',
          hints: ['별에서 4개를 지워봐요', '6-4를 계산해봐요', '정답은 2이에요'],
          explanation: '6-4=2, 별 2개 남아요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '8 – 3 = ?',
          answer: '5',
          hints: ['8에서 3번 거꾸로 세어봐요', '8, 7, 6, 5!', '정답은 5이에요'],
          explanation: '8-3=5이에요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '🍦🍦🍦🍦🍦🍦🍦 아이스크림\n7개 중 5개를 먹었어요.\n몇 개 남았나요?',
          answer: '2',
          hints: ['7개에서 5개를 지워봐요', '7-5를 계산해봐요', '정답은 2이에요'],
          explanation: '7-5=2, 아이스크림 2개 남아요!',
          difficulty: 4,
        ),
      ],
    ),
  ],
);

// ── Level 5: 크기 비교 ───────────────────────────────────────────────────────

final _level5Step = LearningStep(
  stepId: 'math_level_5_step_1',
  stepTitle: '크기 비교',
  stepDescription: '어느 쪽이 더 클까요?',
  cycles: [
    LearningCycle(
      cycleId: 'math_l5_c1',
      type: CycleType.concept,
      slides: const [
        ConceptSlide(
          image: '⚖️',
          text: '두 수 중 어느 쪽이 더 큰지,\n작은지 알아보는 거예요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '↔️',
          text: '> 는 왼쪽이 크다, < 는 오른쪽이 커요.\n3 > 1, 2 < 5 이렇게 써요!',
          confirmButtonText: '다음',
        ),
        ConceptSlide(
          image: '🏆',
          text: '7과 4 중 어느 게 더 클까요?\n손가락으로 세어 비교해봐요!',
          confirmButtonText: '이해했어요!',
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l5_c2',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '3과 5 중에서\n더 큰 수는?',
          options: ['3', '5', '같아요'],
          answer: '5',
          hints: ['손가락으로 3개, 5개를 세어봐요', '5개가 3개보다 많아요', '정답은 5이에요'],
          explanation: '5가 3보다 커요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '7과 4 중에서\n더 작은 수는?',
          options: ['7', '4', '같아요'],
          answer: '4',
          hints: ['손가락으로 7개, 4개를 세어봐요', '4개가 7개보다 적어요', '정답은 4이에요'],
          explanation: '4가 7보다 작아요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '2 ○ 8\n○ 안에 들어갈 기호는?',
          options: ['>', '<', '='],
          answer: '<',
          hints: ['2와 8을 비교해봐요', '2가 더 작아요', '작은 쪽은 < 기호를 써요'],
          explanation: '2 < 8, 2가 8보다 작아요!',
          difficulty: 2,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l5_c3',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '1, 5, 3 중에서\n가장 큰 수는?',
          options: ['1', '5', '3'],
          answer: '5',
          hints: ['세 수를 순서대로 나열해봐요', '1 < 3 < 5이에요', '정답은 5이에요'],
          explanation: '5가 가장 큰 수예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '6 ○ 6\n○ 안에 들어갈 기호는?',
          options: ['>', '<', '='],
          answer: '=',
          hints: ['6과 6을 비교해봐요', '같은 숫자예요', '같을 때는 = 기호를 써요'],
          explanation: '6 = 6, 두 수가 같아요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '9와 7 중에서\n더 큰 수는?',
          options: ['9', '7', '같아요'],
          answer: '9',
          hints: ['9개와 7개를 세어봐요', '9개가 7개보다 많아요', '정답은 9이에요'],
          explanation: '9가 7보다 커요!',
          difficulty: 2,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l5_c4',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '2, 8, 5 중에서\n가장 작은 수는?',
          options: ['2', '8', '5'],
          answer: '2',
          hints: ['세 수를 순서대로 나열해봐요', '2 < 5 < 8이에요', '정답은 2이에요'],
          explanation: '2가 가장 작은 수예요!',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '4 + 2 ○ 5\n○ 안에 들어갈 기호는?',
          options: ['>', '<', '='],
          answer: '>',
          hints: ['4+2를 먼저 계산해봐요', '4+2=6이에요', '6과 5를 비교하면?'],
          explanation: '4+2=6이고, 6>5이에요!',
          difficulty: 3,
        ),
        ChoiceQuestion(
          questionText: '10 – 3 ○ 6\n○ 안에 들어갈 기호는?',
          options: ['>', '<', '='],
          answer: '>',
          hints: ['10-3을 먼저 계산해봐요', '10-3=7이에요', '7과 6을 비교하면?'],
          explanation: '10-3=7이고, 7>6이에요!',
          difficulty: 3,
        ),
      ],
    ),
    LearningCycle(
      cycleId: 'math_l5_c5',
      type: CycleType.shortAnswer,
      shortAnswerQuestions: const [
        ShortAnswerQuestion(
          questionText: '3, 7, 5 중에서\n가장 큰 수는?',
          answer: '7',
          hints: ['세 수를 순서대로 나열해봐요', '3 < 5 < 7이에요', '정답은 7이에요'],
          explanation: '7이 가장 큰 수예요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '1, 4, 9, 2 중에서\n가장 작은 수는?',
          answer: '1',
          hints: ['네 수를 순서대로 나열해봐요', '1 < 2 < 4 < 9이에요', '정답은 1이에요'],
          explanation: '1이 가장 작은 수예요!',
          difficulty: 4,
        ),
        ShortAnswerQuestion(
          questionText: '5보다 크고\n8보다 작은 수를\n모두 더하면?',
          answer: '13',
          hints: ['5보다 크고 8보다 작은 수를 찾아봐요', '6과 7이 해당돼요', '6+7=13이에요'],
          explanation: '6과 7이 해당되고, 6+7=13이에요!',
          difficulty: 4,
        ),
      ],
    ),
  ],
);

// ── Level 6 (임시): 분수 렌더링 테스트용 ─────────────────────────────────────

final _level6Step = LearningStep(
  stepId: 'math_grade6_step_1',
  stepTitle: '분수',
  stepDescription: '분수를 알아봐요',
  cycles: [
    // Cycle 1: concept — 자연수 ÷ 자연수 = 분수
    LearningCycle(
      cycleId: 'math_l6_c1',
      type: CycleType.concept,
      slides: const [
        ConceptSlide(
          image: '🌾',
          richText: [
            PlainSpan('밀가루 3kg을 4봉지에 똑같이 나눠 담으려고 해요. 한 봉지에 몇 kg씩 담으면 될까요?'),
          ],
          text: '밀가루 3kg을 4봉지에 똑같이 나눠 담으려고 해요. 한 봉지에 몇 kg씩 담으면 될까요?',
          confirmButtonText: '확인',
        ),
        ConceptSlide(
          image: '➗',
          richText: [
            PlainSpan('3 ÷ 4는 딱 나눠지지 않아요. 이럴 때는 분수로 나타낼 수 있어요! 나눠지는 수 3이 분자, 나누는 수 4가 분모가 돼요. 3 ÷ 4 = '),
            FractionSpan(numerator: 3, denominator: 4),
            PlainSpan('예요!'),
          ],
          text: '3 ÷ 4는 딱 나눠지지 않아요. 이럴 때는 분수로 나타낼 수 있어요! 3 ÷ 4 = 3/4예요!',
          confirmButtonText: '확인',
        ),
        ConceptSlide(
          image: '📦',
          richText: [
            PlainSpan('자연수 ÷ 자연수는 분수로 나타낼 수 있어요. 한 봉지에 '),
            FractionSpan(numerator: 3, denominator: 4),
            PlainSpan('kg씩 담으면 돼요. 같이 해봐요!'),
          ],
          text: '자연수 ÷ 자연수는 분수로 나타낼 수 있어요. 한 봉지에 3/4kg씩 담으면 돼요.',
          confirmButtonText: '시작해볼까요?',
        ),
      ],
    ),
    // Cycle 2: choice — 분수 크기 비교 (fraction options)
    LearningCycle(
      cycleId: 'math_l6_c2',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '다음 중 가장 큰 분수는?',
          richQuestionText: [PlainSpan('다음 중 가장 큰 분수는?')],
          options: ['1/2', '1/3', '1/4'],
          fractionOptions: [
            FractionValue(numerator: 1, denominator: 2),
            FractionValue(numerator: 1, denominator: 3),
            FractionValue(numerator: 1, denominator: 4),
          ],
          answer: '1/2',
          fractionAnswer: FractionValue(numerator: 1, denominator: 2),
          hints: ['분모가 작을수록 더 큰 분수예요!'],
          richHints: [
            [
              PlainSpan('분모(아래 수)가 작을수록 '),
              FractionSpan(numerator: 1, denominator: 2),
              PlainSpan(' 처럼 더 큰 분수가 돼요!'),
            ],
          ],
          explanation: '1/2이 가장 커요!',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '다음 중 가장 작은 분수는?',
          richQuestionText: [
            PlainSpan('다음 중 '),
            PlainSpan('가장 작은'),
            PlainSpan(' 분수는?'),
          ],
          options: ['2/5', '2/3', '2/7'],
          fractionOptions: [
            FractionValue(numerator: 2, denominator: 5),
            FractionValue(numerator: 2, denominator: 3),
            FractionValue(numerator: 2, denominator: 7),
          ],
          answer: '2/7',
          fractionAnswer: FractionValue(numerator: 2, denominator: 7),
          hints: ['분자가 같을 때는 분모가 클수록 작아요!'],
          explanation: '2/7이 가장 작아요!',
          difficulty: 2,
        ),
      ],
    ),
    // Cycle 3: short_answer — 분수 직접 입력
    LearningCycle(
      cycleId: 'math_l6_c3',
      type: CycleType.shortAnswer,
      shortAnswerQuestions: const [
        ShortAnswerQuestion(
          questionText: '사과 8개 중 3개를 먹었어요.\n먹은 사과는 전체의 얼마인가요?',
          richQuestionText: [
            PlainSpan('사과 8개 중 3개를 먹었어요.\n먹은 사과는 전체의 얼마인가요?'),
          ],
          answer: '3/8',
          fractionAnswer: FractionValue(numerator: 3, denominator: 8),
          hints: ['전체가 8개니까 분모는 8이에요!', '먹은 게 3개니까 분자는 3이에요!'],
          richHints: [
            [PlainSpan('전체가 8개니까 분모(아래)는 8이에요!')],
            [
              PlainSpan('먹은 게 3개니까 분자(위)는 3 → 정답은 '),
              FractionSpan(numerator: 3, denominator: 8),
              PlainSpan(' 이에요!'),
            ],
          ],
          explanation: '3/8이에요!',
          difficulty: 3,
        ),
        ShortAnswerQuestion(
          questionText: '리본 12cm 중 5cm를 잘랐어요.\n자른 부분은 전체의 얼마인가요?',
          answer: '5/12',
          fractionAnswer: FractionValue(numerator: 5, denominator: 12, unit: ''),
          hints: ['분모는 전체 길이, 분자는 자른 길이예요!'],
          explanation: '5/12이에요!',
          difficulty: 3,
        ),
      ],
    ),
  ],
);

// ── Korean Level 1: 비 오는 날 (grade3_step1) ─────────────────────────────────

final _koreanLevel1Step = LearningStep(
  stepId: 'grade3_step1',
  stepTitle: '비 오는 날',
  stepDescription: '감각적 표현과 흉내말을 배워요',
  cycles: [
    // Cycle 1: word_card → concept (주룩주룩, 후두둑, 촉촉)
    LearningCycle(
      cycleId: 'korean_l1_c1',
      type: CycleType.concept,
      slides: const [
        ConceptSlide(
          image: '🌧️',
          text: '주룩주룩\n\n비가 많이 내릴 때 나는 소리예요!',
          confirmButtonText: '이해했어!',
        ),
        ConceptSlide(
          image: '💧',
          text: '후두둑\n\n굵은 빗방울이 떨어질 때 나는 소리예요!',
          confirmButtonText: '이해했어!',
        ),
        ConceptSlide(
          image: '🌿',
          text: '촉촉\n\n물기가 살짝 있어서 부드러운 느낌이에요!',
          confirmButtonText: '시작해볼게!',
        ),
      ],
    ),
    // Cycle 2: fact_check ->  choice 
    LearningCycle(
      cycleId: 'korean_l1_c2',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '오늘 날씨는 비가 왔나요?\n\n📖 "오늘은 비가 주룩주룩 내렸어요."',
          options: ['O', 'X'],
          answer: 'O',
          hints: ['첫 번째 문장을 다시 읽어봐요!', "'비가 주룩주룩'이라는 표현이 있어요. 찾았나요?"],
          explanation: '맞아요! 오늘은 비가 주룩주룩 내렸어요.',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '민준이는 밖에 나가서 비를 맞았나요?\n\n📖 "민준이는 창문 너머로 빗소리를 들으며 앉아 있었어요."',
          options: ['O', 'X'],
          answer: 'X',
          hints: ['민준이가 어디에 있었는지 찾아봐요!', "'창문 너머로'라고 했어요. 창문 안에서 보고 있었던 거예요!"],
          explanation: '아니에요! 민준이는 창문 안에서 빗소리를 들었어요.',
          difficulty: 1,
        ),
        ChoiceQuestion(
          questionText: '민준이가 코로 느낀 것은 무엇인가요?\n\n📖 "흙냄새가 코끝에 살며시 풍겨왔어요."',
          options: ['흙냄새', '꽃향기', '빵냄새'],
          answer: '흙냄새',
          hints: ['코로 느낀 것을 글에서 찾아봐요!', "'코끝에 풍겨왔어요'라는 문장을 읽어봐요. 거의 다 왔어요!"],
          explanation: '민준이는 흙냄새를 맡았어요!',
          difficulty: 1,
        ),
      ],
    ),
    // Cycle 3: diagram_order → choice (사건 순서)
    LearningCycle(
      cycleId: 'korean_l1_c3',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '이야기에서 가장 먼저 일어난 일은 무엇인가요?',
          options: ['비가 내리기 시작했다', '흙냄새가 났다', '꽃잎을 바라봤다'],
          answer: '비가 내리기 시작했다',
          hints: ['이야기에서 맨 처음 일어난 일을 찾아봐요!', '글의 첫 번째 문장을 읽어봐요. 할 수 있어요!'],
          explanation: '가장 먼저 비가 주룩주룩 내리기 시작했어요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '마지막에 민준이가 한 일은 무엇인가요?\n\n📖 "민준이는 촉촉하게 젖은 꽃잎을 바라보며 미소를 지었어요."',
          options: ['밖으로 나갔다', '젖은 꽃잎을 보며 미소 지었다', '창문을 닫았다'],
          answer: '젖은 꽃잎을 보며 미소 지었다',
          hints: ['이야기의 마지막 문장을 찾아봐요!', "'미소를 지었어요'라는 표현이 있어요. 찾았나요?"],
          explanation: '마지막으로 민준이는 촉촉한 꽃잎을 보며 미소를 지었어요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '빗소리를 들으며 민준이는 어디에 있었나요?\n\n📖 "민준이는 창문 너머로 빗소리를 들으며 앉아 있었어요."',
          options: ['마당', '창가', '학교'],
          answer: '창가',
          hints: ['민준이가 빗소리를 어디서 들었는지 찾아봐요!', "'창문 너머로'라는 표현에서 힌트를 얻어봐요. 거의 다 왔어요!"],
          explanation: '민준이는 창가에 앉아서 빗소리를 들었어요!',
          difficulty: 2,
        ),
      ],
    ),
    // Cycle 4: inference → choice (추론)
    LearningCycle(
      cycleId: 'korean_l1_c4',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '꽃잎을 보면서 민준이는 어떤 기분이었을까요?\n\n📖 "민준이는 촉촉하게 젖은 꽃잎을 바라보며 미소를 지었어요."',
          options: ['행복했을 것이다', '무서웠을 것이다', '화가 났을 것이다'],
          answer: '행복했을 것이다',
          hints: ['미소를 짓는다는 건 어떤 기분일 때일까요?', '기분이 좋을 때 우리도 미소를 짓잖아요. 맞아요, 잘하고 있어요!'],
          explanation: '미소를 짓는 건 기분이 좋을 때예요. 민준이는 행복했을 거예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: "'살며시 풍겨온다'는 게 어떤 뜻인가요?\n\n📖 \"흙냄새가 코끝에 살며시 풍겨왔어요.\"",
          options: ['아주 강하게 확 나는 것', '살짝 부드럽게 나는 것', '전혀 안 나는 것'],
          answer: '살짝 부드럽게 나는 것',
          hints: ["'살며시'가 어떤 뜻인지 생각해봐요!", '살며시는 아주 조용하고 부드럽게라는 뜻이에요. 거의 다 왔어요!'],
          explanation: "'살며시'는 조용하고 부드럽게라는 뜻이에요!",
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '빗방울이 지붕을 두드린다고 했어요.\n빗방울을 무엇처럼 나타낸 건가요?\n\n📖 "후두둑후두둑, 빗방울이 지붕을 두드렸어요."',
          options: ['사람이 손으로 두드리는 것처럼', '새가 날아가는 것처럼', '물이 흘러가는 것처럼'],
          answer: '사람이 손으로 두드리는 것처럼',
          hints: ["'두드렸어요'는 누가 하는 행동인지 생각해봐요!", '사람이 문을 두드리는 것처럼, 빗방울도 지붕을 두드린다고 했어요. 잘하고 있어요!'],
          explanation: '빗방울을 사람처럼 표현했어요. 이런 걸 감각적 표현이라고 해요!',
          difficulty: 3,
        ),
      ],
    ),
    // Cycle 5: summary_fill → choice (요약 빈칸)
    LearningCycle(
      cycleId: 'korean_l1_c5',
      type: CycleType.choice,
      choiceQuestions: const [
        ChoiceQuestion(
          questionText: '빈칸에 알맞은 말을 골라봐요!\n\n"오늘은 비가 [  ?  ] 내렸어요."',
          options: ['주룩주룩', '펑펑', '살살'],
          answer: '주룩주룩',
          hints: ['비가 내리는 소리를 나타내는 흉내말이에요!', '비가 많이 내릴 때 쓰는 표현이에요. 거의 다 왔어요!'],
          explanation: '비가 주룩주룩 내렸어요. 비 내리는 소리를 나타내는 흉내말이에요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '빈칸에 알맞은 말을 골라봐요!\n\n"젖은 꽃잎을 바라보며 민준이는 [  ?  ] 기분이 들었어요."',
          options: ['행복한', '슬픈', '무서운'],
          answer: '행복한',
          hints: ['꽃잎을 보며 미소를 지었어요. 미소를 지을 때는 어떤 기분인가요?', '미소를 지을 때는 기분이 좋을 때예요. 할 수 있어요!'],
          explanation: '꽃잎을 보며 미소를 지었으니, 행복한 기분이었을 거예요!',
          difficulty: 2,
        ),
        ChoiceQuestion(
          questionText: '이 글에서 비 오는 소리를 나타낸 낱말은 무엇인가요?',
          options: ['후두둑후두둑', '쨍그랑쨍그랑', '펑펑'],
          answer: '후두둑후두둑',
          hints: ['빗방울이 지붕을 두드리는 소리를 나타낸 낱말이에요!', "'후'로 시작하는 낱말이에요. 거의 다 왔어요!"],
          explanation: '후두둑후두둑! 빗방울이 지붕을 두드리는 소리예요.',
          difficulty: 2,
        ),
      ],
    ),
  ],
);
