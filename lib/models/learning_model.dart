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

({FractionValue? fractionAnswer, String? answer}) _parseAnswer(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    final frac = FractionValue.fromJson(raw);
    return (fractionAnswer: frac, answer: frac.key);
  }
  if (raw != null) return (fractionAnswer: null, answer: raw as String);
  return (fractionAnswer: null, answer: null);
}

({List<List<RichSpan>>? richHints, List<String> hints}) _parseHints(dynamic raw) {
  final list = (raw as List?) ?? [];
  if (list.isNotEmpty && list.first is List) {
    final rich = list.map<List<RichSpan>>(_parseSpans).toList();
    return (richHints: rich, hints: rich.map(_spansToString).toList());
  }
  return (richHints: null, hints: list.cast<String>());
}

({List<RichSpan>? richExplanation, String? explanation}) _parseExplanation(dynamic raw) {
  if (raw is List) {
    final rich = _parseSpans(raw);
    return (richExplanation: rich, explanation: _spansToString(rich));
  }
  if (raw != null) return (richExplanation: null, explanation: raw as String);
  return (richExplanation: null, explanation: null);
}

// ── Learning models ───────────────────────────────────────────────────────────

enum CycleType { concept, wordCard, choice, shortAnswer }

class ConceptSlide {
  final String image;
  final String text;
  final List<RichSpan>? richText;
  final String confirmButtonText;
  /// 낱말 카드 전용 — 대표 단어 (null이면 일반 개념 슬라이드)
  final String? word;

  const ConceptSlide({
    required this.image,
    required this.text,
    this.richText,
    required this.confirmButtonText,
    this.word,
  });

  List<RichSpan> get spans => richText ?? [PlainSpan(text)];

  factory ConceptSlide.fromJson(Map<String, dynamic> json) {
    final wordStr = json['word'] as String?;
    final descStr = json['description'] ?? json['text'];
    final rich = _parseSpans(descStr ?? wordStr ?? '');
    return ConceptSlide(
      word: wordStr,
      image: json['image'] as String? ?? json['imageUrl'] as String? ?? '',
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
    final rich = _parseSpans(json['text'] ?? json['question_text'] ?? json['question'] ?? '');

    final rawOptions = (json['options'] as List?) ?? [];
    List<FractionValue>? fracOpts;
    List<String> strOpts;
    if (rawOptions.isNotEmpty && rawOptions.first is Map) {
      fracOpts = rawOptions.cast<Map<String, dynamic>>().map(FractionValue.fromJson).toList();
      strOpts = fracOpts.map((f) => f.key).toList();
    } else {
      strOpts = rawOptions.cast<String>();
    }

    final (:fractionAnswer, :answer) = _parseAnswer(json['answer']);
    final (:richHints, :hints) = _parseHints(json['hint'] ?? json['hints']);
    final (:richExplanation, :explanation) = _parseExplanation(json['explanation']);

    return ChoiceQuestion(
      questionText: _spansToString(rich),
      richQuestionText: rich,
      options: strOpts,
      fractionOptions: fracOpts,
      answer: answer,
      fractionAnswer: fractionAnswer,
      hints: hints,
      richHints: richHints,
      explanation: explanation,
      richExplanation: richExplanation,
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
    final rich = _parseSpans(json['text'] ?? json['question_text'] ?? json['question'] ?? '');
    final (:fractionAnswer, :answer) = _parseAnswer(json['answer']);
    final (:richHints, :hints) = _parseHints(json['hint'] ?? json['hints']);
    final (:richExplanation, :explanation) = _parseExplanation(json['explanation']);

    return ShortAnswerQuestion(
      questionText: _spansToString(rich),
      richQuestionText: rich,
      answer: answer,
      fractionAnswer: fractionAnswer,
      hints: hints,
      richHints: richHints,
      explanation: explanation,
      richExplanation: richExplanation,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }
}

const _cycleTypeMap = <String, CycleType>{
  'concept': CycleType.concept,
  'word_card': CycleType.wordCard,
  'choice': CycleType.choice,
  'short_answer': CycleType.shortAnswer,
  'fact_check': CycleType.choice,
  'inference': CycleType.choice,
  'diagram_order': CycleType.choice,
  'summary_fill': CycleType.choice,
};

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
    final typeStr = json['cycle_type'] as String? ?? json['type'] as String? ?? '';
    final type = _cycleTypeMap[typeStr] ?? CycleType.concept;
    // 'cycle_id' → 'cycle_number' (수학) → 'cycle' (국어) 순서로 탐색
    final cycleId = json['cycle_id'] as String? ??
        'cycle_${json['cycle_number'] ?? json['cycle']}';
    final isSlideType =
        type == CycleType.concept || type == CycleType.wordCard;
    // word_card cycles may use 'words' key instead of 'slides'
    final rawSlides = (json['slides'] as List?) ??
        (type == CycleType.wordCard ? json['words'] as List? : null) ??
        [];
    return LearningCycle(
      cycleId: cycleId,
      type: type,
      slides: isSlideType
          ? rawSlides
              .map((s) => ConceptSlide.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      choiceQuestions: type == CycleType.choice
          ? ((json['questions'] as List?) ?? [])
              .map((q) => ChoiceQuestion.fromJson(q as Map<String, dynamic>))
              .toList()
          : null,
      shortAnswerQuestions: type == CycleType.shortAnswer
          ? ((json['questions'] as List?) ?? [])
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
      completedCycles: ((json['completedCycles'] as List<dynamic>?) ?? [])
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

