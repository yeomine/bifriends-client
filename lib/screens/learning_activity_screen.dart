import 'dart:math';
import 'package:flutter/material.dart';
import '../models/learning_model.dart';
import '../services/korean_learning_service.dart';
import '../services/math_learning_service.dart';
import '../widgets/learning_roadmap.dart' show LevelData;
import '../widgets/rich_inline_text.dart';
import '../theme/app_colors.dart';

class LearningActivityScreen extends StatefulWidget {
  final LevelData levelData;
  final int initialStep;
  final VoidCallback? onStepCompleted;
  final String subject;
  final int grade;

  const LearningActivityScreen({
    super.key,
    required this.levelData,
    this.initialStep = 1,
    this.onStepCompleted,
    this.subject = 'math',
    this.grade = 3,
  });

  @override
  State<LearningActivityScreen> createState() => _LearningActivityScreenState();
}

class _LearningActivityScreenState extends State<LearningActivityScreen> {
  LearningStep? _step;
  bool _contentLoading = true;
  late int _currentCycleIdx;
  int _currentQuestionIdx = 0;
  int _hintsShown = 0;
  String? _selectedChoice;
  bool _showWrongFeedback = false;
  bool _showSuccessOverlay = false;
  bool _isLastStepCompleted = false;
  bool _isValidating = false;
  late TextEditingController _answerController;
  late TextEditingController _denominatorController;

  final MathLearningService _mathService = MathLearningService();
  final KoreanLearningService _koreanService = KoreanLearningService();

  bool _useApiValidation = false;
  Passage? _passage;

  @override
  void initState() {
    super.initState();
    _currentCycleIdx = (widget.initialStep - 1).clamp(0, 99);
    _answerController = TextEditingController();
    _answerController.addListener(() => setState(() {}));
    _denominatorController = TextEditingController();
    _denominatorController.addListener(() => setState(() {}));
    _loadContent();
  }

  Future<void> _loadContent() async {
    LearningStep step;
    if (widget.levelData.stepId > 0) {
      try {
        final content = widget.subject == 'korean'
            ? await _koreanService.getStepContent(widget.levelData.stepId)
            : await _mathService.getStepContent(widget.levelData.stepId);
        step = LearningStep(
          stepId: content.stepId.toString(),
          stepTitle: content.stepTitle,
          stepDescription: content.concept,
          cycles: content.cycles,
        );
        _passage = content.passage;
        _useApiValidation = true;
        debugPrint('[Content] 로드 성공: ${content.cycles.length}개 사이클');
        for (final c in content.cycles) {
          debugPrint(
            '[Content]  ${c.cycleId} type=${c.type} slides=${c.slides?.length ?? 'null'}',
          );
        }
      } catch (e, st) {
        debugPrint('[Content] 파싱 실패: $e');
        debugPrint('[Content] $st');
        step = widget.subject == 'korean'
            ? mockKoreanStepForLevel(widget.levelData.level)
            : mockStepForLevel(widget.levelData.level);
        _useApiValidation = false;
      }
    } else {
      step = widget.subject == 'korean'
          ? mockKoreanStepForLevel(widget.levelData.level)
          : mockStepForLevel(widget.levelData.level);
      _useApiValidation = false;
    }
    if (!mounted) return;
    setState(() {
      _step = step;
      _currentCycleIdx = (widget.initialStep - 1).clamp(
        0,
        step.cycles.length - 1,
      );
      _contentLoading = false;
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _denominatorController.dispose();
    super.dispose();
  }

  LearningCycle get _currentCycle => _step!.cycles[_currentCycleIdx];
  int get _totalCycles => _step!.cycles.length;
  bool get _isLastCycle => _currentCycleIdx >= _totalCycles - 1;
  bool get _isLastQuestion =>
      _currentQuestionIdx >= _currentCycle.questionCount - 1;

  // Only used for Korean / mock data local validation
  bool get _isCurrentAnswerCorrectLocal {
    switch (_currentCycle.type) {
      case CycleType.concept:
      case CycleType.wordCard:
        return true;
      case CycleType.choice:
        final q = _currentCycle.choiceQuestions![_currentQuestionIdx];
        return _selectedChoice == q.answer;
      case CycleType.shortAnswer:
        final q = _currentCycle.shortAnswerQuestions![_currentQuestionIdx];
        if (q.fractionAnswer != null) {
          final num = int.tryParse(_answerController.text.trim());
          final den = int.tryParse(_denominatorController.text.trim());
          return num == q.fractionAnswer!.numerator &&
              den == q.fractionAnswer!.denominator;
        }
        return _answerController.text.trim() == q.answer;
    }
  }

  bool get _canProceed {
    if (_isValidating) return false;
    switch (_currentCycle.type) {
      case CycleType.concept:
      case CycleType.wordCard:
        return true;
      case CycleType.choice:
        return _selectedChoice != null;
      case CycleType.shortAnswer:
        final q = _currentCycle.shortAnswerQuestions![_currentQuestionIdx];
        if (q.fractionAnswer != null) {
          final num = int.tryParse(_answerController.text.trim());
          final den = int.tryParse(_denominatorController.text.trim());
          if (_useApiValidation) return num != null && den != null;
          return num != null && den != null && _isCurrentAnswerCorrectLocal;
        }
        if (_useApiValidation) return _answerController.text.trim().isNotEmpty;
        return _answerController.text.trim().isNotEmpty &&
            _isCurrentAnswerCorrectLocal;
    }
  }

  void _resetQuestionState() {
    _selectedChoice = null;
    _hintsShown = 0;
    _showWrongFeedback = false;
    _answerController.clear();
    _denominatorController.clear();
  }

  void _onChoiceTap(String option) {
    if (_showWrongFeedback || _isValidating) return;
    setState(() => _selectedChoice = option);
  }

  Future<void> _onConfirm() async {
    if (!_canProceed) return;
    FocusScope.of(context).unfocus();

    if (_currentCycle.type == CycleType.concept ||
        _currentCycle.type == CycleType.wordCard) {
      _advanceContent();
      return;
    }

    if (_useApiValidation) {
      await _onConfirmWithApi();
    } else {
      _onConfirmLocal();
    }
  }

  void _onConfirmLocal() {
    if (!_isCurrentAnswerCorrectLocal &&
        _currentCycle.type == CycleType.choice) {
      setState(() => _showWrongFeedback = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _showWrongFeedback = false;
            _selectedChoice = null;
          });
        }
      });
      return;
    }
    _advanceContent();
  }

  Future<void> _onConfirmWithApi() async {
    setState(() => _isValidating = true);
    try {
      dynamic answer;
      if (_currentCycle.type == CycleType.choice) {
        answer = _selectedChoice;
      } else {
        final q = _currentCycle.shortAnswerQuestions![_currentQuestionIdx];
        if (q.fractionAnswer != null) {
          answer = {
            'numerator': int.parse(_answerController.text.trim()),
            'denominator': int.parse(_denominatorController.text.trim()),
          };
        } else {
          answer = _answerController.text.trim();
        }
      }

      final result = widget.subject == 'korean'
          ? await _koreanService.validateAnswer(
              stepId: widget.levelData.stepId,
              cycleNumber: _currentCycleIdx + 1,
              questionIndex: _currentQuestionIdx,
              answer: answer as String,
            )
          : await _mathService.validateAnswer(
              stepId: widget.levelData.stepId,
              cycleNumber: _currentCycleIdx + 1,
              questionIndex: _currentQuestionIdx,
              answer: answer,
            );

      if (!mounted) return;
      setState(() => _isValidating = false);

      if (!result.correct) {
        setState(() => _showWrongFeedback = true);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              _showWrongFeedback = false;
              _selectedChoice = null;
            });
          }
        });
        return;
      }
      _advanceContent();
    } catch (_) {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _advanceContent() {
    if (!_isLastQuestion) {
      setState(() {
        _currentQuestionIdx++;
        _resetQuestionState();
      });
    } else {
      _completeCycleAndShow();
    }
  }

  Future<void> _completeCycleAndShow() async {
    final wasLastCycle = _isLastCycle;
    if (_useApiValidation) {
      try {
        await (widget.subject == 'korean'
            ? _koreanService.completeCycle(
                stepId: widget.levelData.stepId,
                cycleNumber: _currentCycleIdx + 1,
              )
            : _mathService.completeCycle(
                stepId: widget.levelData.stepId,
                cycleNumber: _currentCycleIdx + 1,
              ));
      } catch (e) {
        debugPrint('[Complete] completeCycle 에러: $e');
      }
      if (wasLastCycle) {
        try {
          await (widget.subject == 'korean'
              ? _koreanService.completeStep(widget.levelData.stepId)
              : _mathService.completeStep(widget.levelData.stepId));
        } catch (e) {
          debugPrint('[Complete] completeStep 에러: $e');
        }
      }
    }
    if (!mounted) return;
    widget.onStepCompleted?.call();
    setState(() {
      _isLastStepCompleted = wasLastCycle;
      _showSuccessOverlay = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_contentLoading || _step == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCycleContent(
                      key: ValueKey('${_currentCycleIdx}_$_currentQuestionIdx'),
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
          if (_showSuccessOverlay)
            Positioned.fill(
              child: _StepCompletionOverlay(
                isLastStep: _isLastStepCompleted,
                onReturn: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveConceptImagePath(String image) {
    if (image.isEmpty) return '';
    if (image.startsWith('assets/')) return image;
    final folder = widget.subject == 'korean' ? 'study_korean' : 'study_math';
    final filename = (widget.subject == 'math' && !RegExp(r'^g\d_').hasMatch(image))
        ? 'g${widget.grade}_$image'
        : image;
    return 'assets/images/$folder/grade${widget.grade}/$filename';
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE6DF),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 10,
                    width:
                        constraints.maxWidth *
                        ((_currentCycleIdx + 1) / _totalCycles),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_currentCycleIdx + 1}/$_totalCycles',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCycleContent({required Key key}) {
    switch (_currentCycle.type) {
      case CycleType.concept:
      case CycleType.wordCard:
        return _buildConceptSlide(key: key);
      case CycleType.choice:
        return _buildChoiceQuestion(key: key);
      case CycleType.shortAnswer:
        return _buildShortAnswerQuestion(key: key);
    }
  }

  // ── Concept slide ─────────────────────────────────────────────────────────

  Widget _buildConceptSlide({required Key key}) {
    final slides = _currentCycle.slides;
    if (slides == null || slides.isEmpty) {
      return Center(
        key: key,
        child: const Text(
          '슬라이드 데이터를 불러올 수 없어요 😢',
          style: TextStyle(fontSize: 16, color: AppColors.textSub),
        ),
      );
    }
    final slide = slides[_currentQuestionIdx];
    final conceptLabel = _currentCycle.type == CycleType.wordCard
        ? '낱말 카드'
        : '개념 이야기';

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              conceptLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_resolveConceptImagePath(slide.image).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                _resolveConceptImagePath(slide.image),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 28),
          RichInlineText(
            spans: slide.spans,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          _buildQuestionDots(),
        ],
      ),
    );
  }

  // ── Choice question ───────────────────────────────────────────────────────

  Widget _buildChoiceQuestion({required Key key}) {
    final q = _currentCycle.choiceQuestions![_currentQuestionIdx];

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPassagePanel(),
          _buildQuestionLabel('문제 풀기'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: RichInlineText(
              spans: q.questionSpans,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (q.fractionOptions != null)
            Column(
              children: q.fractionOptions!
                  .map((f) => _buildFractionChoiceOption(f, q.answer ?? ''))
                  .toList(),
            )
          else
            Column(
              children: q.options
                  .map((opt) => _buildChoiceOption(opt, q.answer ?? ''))
                  .toList(),
            ),
          const SizedBox(height: 16),
          _buildHintPanel(q.hintSpans),
          const SizedBox(height: 8),
          _buildQuestionDots(),
        ],
      ),
    );
  }

  Widget _buildOptionContainer({
    required String tapKey,
    required Widget Function(Color textColor, bool showWrong) builder,
  }) {
    final isSelected = _selectedChoice == tapKey;
    final showWrong = isSelected && _showWrongFeedback;

    final Color borderColor;
    final Color bgColor;
    if (showWrong) {
      borderColor = const Color(0xFFE57373);
      bgColor = const Color(0xFFFFF3F3);
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = const Color(0xFFF0F8ED);
    } else {
      borderColor = const Color(0xFFDCD5CA);
      bgColor = Colors.white;
    }

    final textColor = showWrong
        ? const Color(0xFFE57373)
        : isSelected
            ? AppColors.primary
            : AppColors.textMain;

    return GestureDetector(
      onTap: () => _onChoiceTap(tapKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (showWrong ? const Color(0xFFE57373) : AppColors.primary)
                        .withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: builder(textColor, showWrong),
      ),
    );
  }

  Widget _buildChoiceOption(String option, String correctAnswer) {
    return _buildOptionContainer(
      tapKey: option,
      builder: (textColor, showWrong) => Row(
        children: [
          Expanded(
            child: Text(
              option,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
          if (showWrong)
            const Icon(Icons.cancel_rounded, color: Color(0xFFE57373), size: 22),
        ],
      ),
    );
  }

  Widget _buildFractionChoiceOption(FractionValue f, String correctAnswer) {
    return _buildOptionContainer(
      tapKey: f.key,
      builder: (textColor, showWrong) => Row(
        children: [
          FractionWidget(numerator: f.numerator, denominator: f.denominator, color: textColor),
          if (f.unit != null) ...[
            const SizedBox(width: 4),
            Text(f.unit!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          ],
          const Spacer(),
          if (showWrong)
            const Icon(Icons.cancel_rounded, color: Color(0xFFE57373), size: 22),
        ],
      ),
    );
  }

  // ── Short answer question ─────────────────────────────────────────────────

  String? _extractUnit(String questionText) {
    if (questionText.contains('얼마')) return '원';
    final match = RegExp(
      r'몇\s+(\S+?)(?:일까요|인가요|이에요|일까|인가)',
    ).firstMatch(questionText);
    return match?.group(1);
  }

  Widget _buildShortAnswerQuestion({required Key key}) {
    final q = _currentCycle.shortAnswerQuestions![_currentQuestionIdx];

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPassagePanel(),
          _buildQuestionLabel('직접 써보기'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: RichInlineText(
              spans: q.questionSpans,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          if (q.fractionAnswer != null)
            _buildFractionAnswerInput(q.fractionAnswer!.unit)
          else
            _buildTextAnswerInput(_extractUnit(q.questionText)),
          const SizedBox(height: 24),
          _buildHintPanel(q.hintSpans),
          const SizedBox(height: 8),
          _buildQuestionDots(),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildPassagePanel() {
    final p = _passage;
    if (p == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCD5CA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.title != null) ...[
            Text(
              p.title!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            p.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTextAnswerInput(String? unit) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
              decoration: InputDecoration(
                hintText: '?',
                hintStyle: const TextStyle(color: Color(0xFFDCD5CA)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCD5CA),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: (_useApiValidation || _isCurrentAnswerCorrectLocal)
                        ? AppColors.primary
                        : const Color(0xFFF3C74B),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 10),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFractionAnswerInput(String? unit) {
    final inputDecoration = InputDecoration(
      hintText: '?',
      hintStyle: const TextStyle(color: Color(0xFFDCD5CA)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCD5CA), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: (_useApiValidation || _isCurrentAnswerCorrectLocal)
              ? AppColors.primary
              : const Color(0xFFF3C74B),
          width: 2,
        ),
      ),
    );
    const fieldStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: AppColors.textMain,
    );

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _answerController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: fieldStyle,
                  decoration: inputDecoration,
                ),
              ),
              Container(
                height: 2,
                width: 100,
                color: AppColors.textMain,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _denominatorController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: fieldStyle,
                  decoration: inputDecoration,
                ),
              ),
            ],
          ),
          if (unit != null) ...[
            const SizedBox(width: 10),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionDots() {
    final count = _currentCycle.questionCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == _currentQuestionIdx;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : const Color(0xFFDCD5CA),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHintPanel(List<List<RichSpan>> hintSpans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hintsShown < hintSpans.length)
          SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: () => setState(() => _hintsShown++),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                '💡 힌트 보기 (${hintSpans.length - _hintsShown}개 남음)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
        for (int i = 0; i < _hintsShown; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '힌트 ${i + 1}: ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA07000),
                    ),
                  ),
                  Expanded(
                    child: RichInlineText(
                      spans: hintSpans[i],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA07000),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isLastOverall = _isLastCycle && _isLastQuestion;
    final isConceptLast =
        _currentCycle.type == CycleType.concept && _isLastQuestion;

    final String label;
    if (isLastOverall) {
      label = '마치기';
    } else if (isConceptLast) {
      label = '이해했어요!';
    } else if (_currentCycle.type == CycleType.concept) {
      label = '다음';
    } else {
      label = '확인';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      color: AppColors.background,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: (_showSuccessOverlay || !_canProceed) ? null : _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primaryDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step completion celebration overlay ──────────────────────────────────────

class _StepCompletionOverlay extends StatefulWidget {
  final bool isLastStep;
  final VoidCallback onReturn;

  const _StepCompletionOverlay({
    required this.isLastStep,
    required this.onReturn,
  });

  @override
  State<_StepCompletionOverlay> createState() => _StepCompletionOverlayState();
}

class _StepCompletionOverlayState extends State<_StepCompletionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<double> _contentScale;

  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _contentScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.elasticOut),
    );

    _generateParticles();
    _confettiController.forward();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _contentController.forward();
    });
  }

  void _generateParticles() {
    final emojis = ['⭐', '🌟', '✨', '🎉', '🎊', '💫', '🌈', '🎈'];
    for (int i = 0; i < 40; i++) {
      // Fan-shaped burst: angles 20°~160° so particles shoot upward in a wide cone
      final angleDeg = 20.0 + _random.nextDouble() * 140.0;
      final angleRad = angleDeg * pi / 180;
      final speed = 0.7 + _random.nextDouble() * 1.0;

      _particles.add(
        _ConfettiParticle(
          emoji: emojis[_random.nextInt(emojis.length)],
          startX: 0.4 + _random.nextDouble() * 0.2, // clustered near center
          startY: 0.88, // near bottom of screen
          velocityX: cos(angleRad) * speed,
          velocityY: -sin(angleRad) * speed, // negative = upward
          gravity: 1.4 + _random.nextDouble() * 0.8, // pulls back down
          delay: _random.nextDouble() * 0.18, // slight stagger
          size: 20 + _random.nextDouble() * 24,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            // Confetti particles — single AnimatedBuilder for all 40 particles
            AnimatedBuilder(
              animation: _confettiController,
              builder: (ctx, _) {
                final progress = _confettiController.value;
                final size = MediaQuery.of(ctx).size;
                return Stack(
                  children: _particles.map((p) {
                    if (progress < p.delay) return const SizedBox.shrink();

                    final t = ((progress - p.delay) / (1 - p.delay)).clamp(
                      0.0,
                      1.0,
                    );
                    // Projectile motion: x = start + vx·t, y = start + vy·t + ½·g·t²
                    final x = (p.startX + p.velocityX * t) * size.width;
                    final y =
                        (p.startY + p.velocityY * t + 0.5 * p.gravity * t * t) *
                        size.height;
                    final opacity = t < 0.6
                        ? 1.0
                        : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);

                    return Positioned(
                      left: x,
                      top: y,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: p.rotationSpeed * t,
                          child: Text(
                            p.emoji,
                            style: TextStyle(fontSize: p.size),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _contentOpacity,
                child: ScaleTransition(
                  scale: _contentScale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌟', style: TextStyle(fontSize: 90)),
                        const SizedBox(height: 20),
                        const Text(
                          '참 잘했어!',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isLastStep
                              ? '모두 완료! 정말 대단해! 🎊'
                              : '다음 단계도 함께 해보자! 🌱',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSub,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: widget.onReturn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '로드맵으로 돌아가기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final String emoji;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double gravity;
  final double delay;
  final double size;
  final double rotationSpeed;

  const _ConfettiParticle({
    required this.emoji,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
    required this.delay,
    required this.size,
    required this.rotationSpeed,
  });
}
