class MindChoice {
  final String id;
  final String text;
  final bool isCorrect;
  final String feedback;
  final String? type;

  const MindChoice({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.feedback,
    this.type,
  });

  factory MindChoice.fromJson(Map<String, dynamic> json) => MindChoice(
    id: json['id'] as String? ?? '',
    text: json['text'] as String? ?? '',
    isCorrect: json['isCorrect'] as bool? ?? false,
    feedback: json['feedback'] as String? ?? '',
    type: json['type'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCorrect': isCorrect,
    'feedback': feedback,
    if (type != null) 'type': type,
  };
}

class MindComicCut {
  final int cut;
  final String text;
  final String? imageUrl;

  const MindComicCut({required this.cut, required this.text, this.imageUrl});

  factory MindComicCut.fromJson(Map<String, dynamic> json) => MindComicCut(
    cut: json['cut'] as int? ?? 0,
    text: json['text'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'cut': cut,
    'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

class MindReward {
  final String type;
  final int amount;

  const MindReward({required this.type, required this.amount});

  factory MindReward.fromJson(Map<String, dynamic> json) => MindReward(
    type: json['type'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {'type': type, 'amount': amount};
}

class MindStep1 {
  final String title;
  final String expression;
  final String emotion;
  final String bodySensation;
  final String situationExample;
  final String? imageUrl;
  final String nextButtonText;

  const MindStep1({
    required this.title,
    required this.expression,
    required this.emotion,
    required this.bodySensation,
    required this.situationExample,
    this.imageUrl,
    required this.nextButtonText,
  });

  factory MindStep1.fromJson(Map<String, dynamic> json) => MindStep1(
    title: json['title'] as String? ?? '',
    expression: json['expression'] as String? ?? '',
    emotion: json['emotion'] as String? ?? '',
    bodySensation: json['bodySensation'] as String? ?? '',
    situationExample: json['situationExample'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    nextButtonText: json['nextButtonText'] as String? ?? '이해했어! 🎯',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'expression': expression,
    'emotion': emotion,
    'bodySensation': bodySensation,
    'situationExample': situationExample,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'nextButtonText': nextButtonText,
  };
}

class MindStep2 {
  final String title;
  final String visualClue;
  final String question;
  final List<MindChoice> choices;
  final String? imageUrl;
  final String retryMessage;
  final String nextButtonText;

  const MindStep2({
    required this.title,
    required this.visualClue,
    required this.question,
    required this.choices,
    this.imageUrl,
    required this.retryMessage,
    required this.nextButtonText,
  });

  int get correctIndex => choices.indexWhere((c) => c.isCorrect);

  factory MindStep2.fromJson(Map<String, dynamic> json) => MindStep2(
    title: json['title'] as String? ?? '',
    visualClue: json['visualClue'] as String? ?? '',
    question: json['question'] as String? ?? '',
    choices: (json['choices'] as List<dynamic>?)
            ?.map((e) => MindChoice.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    imageUrl: json['imageUrl'] as String?,
    retryMessage: json['retryMessage'] as String? ?? '다시 생각해봐!',
    nextButtonText: json['nextButtonText'] as String? ?? '다음으로',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'visualClue': visualClue,
    'question': question,
    'choices': choices.map((c) => c.toJson()).toList(),
    if (imageUrl != null) 'imageUrl': imageUrl,
    'retryMessage': retryMessage,
    'nextButtonText': nextButtonText,
  };
}

class MindStep3 {
  final String title;
  final List<MindComicCut> comic;
  final String question;
  final List<MindChoice> choices;
  final String retryMessage;
  final String nextButtonText;

  const MindStep3({
    required this.title,
    required this.comic,
    required this.question,
    required this.choices,
    required this.retryMessage,
    required this.nextButtonText,
  });

  int get correctIndex => choices.indexWhere((c) => c.isCorrect);

  factory MindStep3.fromJson(Map<String, dynamic> json) => MindStep3(
    title: json['title'] as String? ?? '',
    comic: (json['comic'] as List<dynamic>?)
            ?.map((e) => MindComicCut.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    question: json['question'] as String? ?? '',
    choices: (json['choices'] as List<dynamic>?)
            ?.map((e) => MindChoice.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    retryMessage: json['retryMessage'] as String? ?? '만화를 다시 살펴봐!',
    nextButtonText: json['nextButtonText'] as String? ?? '다음으로',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'comic': comic.map((c) => c.toJson()).toList(),
    'question': question,
    'choices': choices.map((c) => c.toJson()).toList(),
    'retryMessage': retryMessage,
    'nextButtonText': nextButtonText,
  };
}

class MindStep4 {
  final String title;
  final String leoIntro;
  final String question;
  final List<MindChoice> choices;
  final String retryMessage;
  final String successMessage;
  final MindReward? reward;
  final String completeButtonText;

  const MindStep4({
    required this.title,
    required this.leoIntro,
    required this.question,
    required this.choices,
    required this.retryMessage,
    required this.successMessage,
    this.reward,
    required this.completeButtonText,
  });

  int get correctIndex => choices.indexWhere((c) => c.isCorrect);

  factory MindStep4.fromJson(Map<String, dynamic> json) => MindStep4(
    title: json['title'] as String? ?? '',
    leoIntro: json['leoIntro'] as String? ?? '',
    question: json['question'] as String? ?? '',
    choices: (json['choices'] as List<dynamic>?)
            ?.map((e) => MindChoice.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    retryMessage: json['retryMessage'] as String? ?? '다시 생각해봐!',
    successMessage: json['successMessage'] as String? ?? '정말 잘했어요! 🌟',
    reward: json['reward'] != null
        ? MindReward.fromJson(json['reward'] as Map<String, dynamic>)
        : null,
    completeButtonText: json['completeButtonText'] as String? ?? '완료! 🎯',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'leoIntro': leoIntro,
    'question': question,
    'choices': choices.map((c) => c.toJson()).toList(),
    'retryMessage': retryMessage,
    'successMessage': successMessage,
    if (reward != null) 'reward': reward!.toJson(),
    'completeButtonText': completeButtonText,
  };
}

class MindSteps {
  final MindStep1 step1;
  final MindStep2? step2;
  final MindStep3? step3;
  final MindStep4? step4;

  const MindSteps({
    required this.step1,
    this.step2,
    this.step3,
    this.step4,
  });

  factory MindSteps.fromJson(Map<String, dynamic> json) => MindSteps(
    step1: MindStep1.fromJson(
      (json['step1'] as Map<String, dynamic>?) ?? {},
    ),
    step2: json['step2'] != null
        ? MindStep2.fromJson(json['step2'] as Map<String, dynamic>)
        : null,
    step3: json['step3'] != null
        ? MindStep3.fromJson(json['step3'] as Map<String, dynamic>)
        : null,
    step4: json['step4'] != null
        ? MindStep4.fromJson(json['step4'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'step1': step1.toJson(),
    if (step2 != null) 'step2': step2!.toJson(),
    if (step3 != null) 'step3': step3!.toJson(),
    if (step4 != null) 'step4': step4!.toJson(),
  };
}

class MindScenario {
  final String setId;
  final String emotion;
  final String situation;
  final String learnedExpression;
  final MindSteps steps;
  final bool isFallback;
  final String? completedAt;

  const MindScenario({
    required this.setId,
    required this.emotion,
    required this.situation,
    required this.learnedExpression,
    required this.steps,
    required this.isFallback,
    this.completedAt,
  });

  factory MindScenario.fromJson(Map<String, dynamic> json) => MindScenario(
    setId: json['setId'] as String? ?? '',
    emotion: json['emotion'] as String? ?? '',
    situation: json['situation'] as String? ?? '',
    learnedExpression: json['learnedExpression'] as String? ?? '',
    steps: MindSteps.fromJson(
      (json['steps'] as Map<String, dynamic>?) ?? {},
    ),
    isFallback: json['isFallback'] as bool? ?? false,
    completedAt: json['completedAt'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'setId': setId,
    'emotion': emotion,
    'situation': situation,
    'learnedExpression': learnedExpression,
    'steps': steps.toJson(),
    'isFallback': isFallback,
    if (completedAt != null) 'completedAt': completedAt,
  };
}

class MindSessionSummary {
  final String setId;
  final String emotion;
  final String learnedExpression;
  final String completedAt;
  final bool isFallback;

  const MindSessionSummary({
    required this.setId,
    required this.emotion,
    required this.learnedExpression,
    required this.completedAt,
    required this.isFallback,
  });

  factory MindSessionSummary.fromJson(Map<String, dynamic> json) =>
      MindSessionSummary(
        setId: json['setId'] as String? ?? '',
        emotion: json['emotion'] as String? ?? '',
        learnedExpression: json['learnedExpression'] as String? ?? '',
        completedAt: json['completedAt'] as String? ?? '',
        isFallback: json['isFallback'] as bool? ?? false,
      );
}
