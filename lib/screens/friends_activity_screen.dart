import 'package:flutter/material.dart';
import '../models/friends_activity_model.dart';
import '../models/mind_model.dart';
import '../services/mind_service.dart';
import '../theme/app_colors.dart';

const int _totalSteps = 4;

class FriendsActivityScreen extends StatefulWidget {
  final MindScenario scenario;
  final bool isReview;

  const FriendsActivityScreen({
    super.key,
    required this.scenario,
    this.isReview = false,
  });

  @override
  State<FriendsActivityScreen> createState() => _FriendsActivityScreenState();
}

class _FriendsActivityScreenState extends State<FriendsActivityScreen> {
  int _currentStep = 0;
  bool _showSuccessOverlay = false;
  bool _isSaving = false;

  // Step 2 state
  int _step2SelectedIndex = -1;
  bool _step2Evaluated = false;
  bool _step2IsCorrect = false;

  // Step 3 state
  late final PageController _step3PageController;
  int _step3Panel = 0;
  int _step3SelectedIndex = -1;
  bool _step3Evaluated = false;
  bool _step3IsCorrect = false;

  // Step 4 state
  int _step4SelectedIndex = -1;
  bool _step4Evaluated = false;
  bool _step4IsCorrect = false;

  EmotionType get _emotionType =>
      EmotionType.fromString(widget.scenario.emotion);

  @override
  void initState() {
    super.initState();
    _step3PageController = PageController();
  }

  @override
  void dispose() {
    _step3PageController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _showSuccessOverlay = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showSuccessOverlay = false;
            _currentStep++;
          });
        }
      });
    }
  }

  Future<void> _saveAndComplete() async {
    if (widget.isReview) {
      _showCompletionDialog(0, isReview: true);
      return;
    }
    setState(() => _isSaving = true);
    int rewardAmount = 0;
    try {
      rewardAmount = await MindService().saveSession(widget.scenario);
    } catch (_) {}
    if (mounted) setState(() => _isSaving = false);
    _showCompletionDialog(rewardAmount);
  }

  void _showCompletionDialog(int rewardAmount, {bool isReview = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isReview ? '📖' : '🎯',
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 20),
              Text(
                isReview ? '다시 잘 풀었어!' : '모두 이해했어!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isReview ? '배운 표현, 잘 기억하고 있구나!' : '오늘 배운 표현들을 잘 기억해줘!',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub,
                ),
              ),
              if (rewardAmount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5ECD8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$rewardAmount 🌱',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '완료!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildTopBar(),
                  const SizedBox(height: 16),
                  if (_currentStep == 0) ...[
                    _buildBearRow(),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _buildCurrentStep(key: ValueKey(_currentStep)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        if (_showSuccessOverlay) _buildSuccessOverlay(),
        if (_isSaving)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.92),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primary,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '잘 이해했어! 👏',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.scenario.situation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildProgressBar(),
        const SizedBox(width: 8),
        Text(
          '${_currentStep + 1}/$_totalSteps',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 52,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFDDD8D0),
        borderRadius: BorderRadius.circular(11),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: constraints.maxWidth * (_currentStep + 1) / _totalSteps,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBearRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFF5C9B8),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/leo_defaultface.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '오늘 배울 표현은 이거야! ✨',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep({required Key key}) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(key: key);
      case 1:
        final step2 = widget.scenario.steps.step2;
        if (step2 == null) {
          return _buildComingSoonPlaceholder(key: key, stepLabel: 'Step 2');
        }
        return _buildStep2(key: key, data: step2);
      case 2:
        final step3 = widget.scenario.steps.step3;
        if (step3 == null) {
          return _buildComingSoonPlaceholder(key: key, stepLabel: 'Step 3');
        }
        return _buildStep3(key: key, data: step3);
      case 3:
        final step4 = widget.scenario.steps.step4;
        if (step4 == null) {
          return _buildComingSoonPlaceholder(key: key, stepLabel: 'Step 4');
        }
        return _buildStep4(key: key, data: step4);
      default:
        return _buildComingSoonPlaceholder(
          key: key,
          stepLabel: 'Step ${_currentStep + 1}',
        );
    }
  }

  // ─────────────────────────────────────────────
  // Step 1 — 관용 표현 학습
  // ─────────────────────────────────────────────

  Widget _buildStep1({required Key key}) {
    final step1 = widget.scenario.steps.step1;
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Text(
              '"${step1.expression}"',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEBE6DF), thickness: 1),
            const SizedBox(height: 16),
            _buildCharacterImage(step1.imageUrl, imageType: 'body'),
            const SizedBox(height: 24),
            _buildSectionBlock(
              label: '우리 몸의 느낌',
              content: step1.bodySensation,
            ),
            const SizedBox(height: 16),
            _buildSectionBlock(
              label: '이럴 때 이런 마음이 들어',
              content: step1.situationExample,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showSuccessOverlay ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textMain,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.textMain.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  step1.nextButtonText.isNotEmpty
                      ? step1.nextButtonText
                      : '이해했어! 🎯',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterImage(String? imageUrl,
      {String imageType = 'body'}) {
    final fallbackPath = imageType == 'face'
        ? _emotionType.step2Path
        : _emotionType.step1Path;

    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) =>
              _assetFallbackImage(fallbackPath, width: 160, height: 160),
        ),
      );
    }
    return _assetFallbackImage(fallbackPath, width: 160, height: 160);
  }

  Widget _assetFallbackImage(String path, {double? width, double? height}) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.face, size: 64, color: AppColors.textSub),
        ),
      ),
    );
  }

  Widget _buildSectionBlock({required String label, required String content}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 2 — 얼굴 확대 이미지 + 감정 선택 퀴즈
  // ─────────────────────────────────────────────

  Widget _buildStep2({required Key key, required MindStep2 data}) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFaceCard(data),
          const SizedBox(height: 16),
          _buildQuestionPill(data.question),
          const SizedBox(height: 12),
          for (int i = 0; i < data.choices.length; i++) ...[
            _buildStep2Choice(data, i),
            if (i < data.choices.length - 1) const SizedBox(height: 10),
          ],
          if (_step2Evaluated &&
              _step2SelectedIndex != -1 &&
              _step2SelectedIndex != data.correctIndex) ...[
            const SizedBox(height: 12),
            _buildWrongExplanation(
              data.choices[_step2SelectedIndex].feedback,
            ),
            const SizedBox(height: 8),
            _buildRetryHint(data.retryMessage),
          ],
          if (_step2Evaluated && _step2IsCorrect) ...[
            const SizedBox(height: 12),
            _buildSuccessBox(data.choices[data.correctIndex].feedback),
          ],
          const SizedBox(height: 16),
          _buildStep2ActionButton(data),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFaceCard(MindStep2 data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _buildCharacterImage(data.imageUrl, imageType: 'face'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👀 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      data.visualClue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPill(String question) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '"$question"',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildStep2Choice(MindStep2 data, int index) {
    final choice = data.choices[index];
    final isSelected = _step2SelectedIndex == index;
    final isCorrect = index == data.correctIndex;
    final correctConfirmed = _step2Evaluated && _step2IsCorrect;

    Color borderColor = const Color(0xFFEBE6DF);
    Color bgColor = Colors.white;
    Color textColor = AppColors.textMain;

    if (correctConfirmed && isCorrect) {
      borderColor = AppColors.primary;
      bgColor = const Color(0xFFEAF3E8);
      textColor = AppColors.primary;
    } else if (isSelected) {
      if (!_step2Evaluated) {
        borderColor = AppColors.primary.withValues(alpha: 0.5);
        bgColor = const Color(0xFFF0F6EE);
        textColor = AppColors.primary;
      } else if (isCorrect) {
        borderColor = AppColors.primary;
        bgColor = const Color(0xFFEAF3E8);
        textColor = AppColors.primary;
      } else {
        borderColor = const Color(0xFFE8A09A);
        bgColor = const Color(0xFFFFF2F1);
        textColor = const Color(0xFFD04B44);
      }
    }

    return GestureDetector(
      onTap: () {
        if (correctConfirmed) {
          if (isCorrect) return;
          setState(() => _step2SelectedIndex = index);
        } else {
          setState(() {
            _step2SelectedIndex = index;
            if (_step2Evaluated && !_step2IsCorrect) _step2Evaluated = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                choice.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isSelected ? textColor : AppColors.textSub,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongExplanation(String explanation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDAD8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              explanation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD04B44),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryHint(String hint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE09A), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('⭐ ', style: TextStyle(fontSize: 22)),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2ActionButton(MindStep2 data) {
    final isConfirmed = _step2Evaluated && _step2IsCorrect;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showSuccessOverlay
            ? null
            : () {
                if (isConfirmed) {
                  _handleNext();
                } else {
                  if (_step2SelectedIndex == -1) return;
                  setState(() {
                    _step2Evaluated = true;
                    _step2IsCorrect =
                        _step2SelectedIndex == data.correctIndex;
                  });
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isConfirmed
                ? (data.nextButtonText.isNotEmpty
                    ? data.nextButtonText
                    : '다음으로')
                : '이 마음 같아! 💕',
            key: ValueKey(isConfirmed),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 3 — 만화 캐러셀 + 감정 원인 퀴즈
  // ─────────────────────────────────────────────

  Widget _buildStep3({required Key key, required MindStep3 data}) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildComicCard(data),
          const SizedBox(height: 16),
          _buildQuestionPill(data.question),
          const SizedBox(height: 12),
          for (int i = 0; i < data.choices.length; i++) ...[
            _buildStep3Choice(data, i),
            if (i < data.choices.length - 1) const SizedBox(height: 10),
          ],
          if (_step3Evaluated &&
              _step3SelectedIndex != -1 &&
              _step3SelectedIndex != data.correctIndex) ...[
            const SizedBox(height: 12),
            _buildStep3WrongGuidance(
              data.choices[_step3SelectedIndex].feedback,
            ),
            const SizedBox(height: 8),
            _buildRetryHint(data.retryMessage),
          ],
          if (_step3Evaluated && _step3IsCorrect) ...[
            const SizedBox(height: 12),
            _buildStep3CorrectExplanation(
              data.choices[data.correctIndex].feedback,
            ),
          ],
          const SizedBox(height: 16),
          _buildStep3ActionButton(data),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildComicCard(MindStep3 data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: PageView.builder(
                    controller: _step3PageController,
                    itemCount: data.comic.length,
                    onPageChanged: (i) => setState(() => _step3Panel = i),
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(52, 36, 48, 16),
                        child: _buildPanelImage(data.comic[i].imageUrl, i),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(_step3Panel),
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_step3Panel + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_step3Panel > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _step3PageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: AppColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_step3Panel < data.comic.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _step3PageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                data.comic[_step3Panel].text,
                key: ValueKey(_step3Panel),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(data.comic.length, (i) {
                final active = i == _step3Panel;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : const Color(0xFFD9D3CB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelImage(String? imageUrl, int panelIndex) {
    final fallbackPath = _emotionType.panelPath(panelIndex);

    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) =>
              _assetPanelFallback(fallbackPath),
        ),
      );
    }
    return _assetPanelFallback(fallbackPath);
  }

  Widget _assetPanelFallback(String path) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 56,
            color: AppColors.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildStep3Choice(MindStep3 data, int index) {
    final choice = data.choices[index];
    final isSelected = _step3SelectedIndex == index;
    final isCorrect = index == data.correctIndex;
    final correctConfirmed = _step3Evaluated && _step3IsCorrect;

    Color borderColor = const Color(0xFFEBE6DF);
    Color bgColor = Colors.white;
    Color textColor = AppColors.textMain;
    Color numBgColor = AppColors.cardLight;
    Color numTextColor = AppColors.textSub;

    if (correctConfirmed && isCorrect) {
      borderColor = AppColors.primary;
      bgColor = const Color(0xFFEAF3E8);
      textColor = AppColors.primary;
      numBgColor = AppColors.primary;
      numTextColor = Colors.white;
    } else if (isSelected) {
      if (!_step3Evaluated) {
        borderColor = AppColors.primary.withValues(alpha: 0.5);
        bgColor = const Color(0xFFF0F6EE);
        textColor = AppColors.primary;
        numBgColor = AppColors.primary.withValues(alpha: 0.5);
        numTextColor = Colors.white;
      } else if (isCorrect) {
        borderColor = AppColors.primary;
        bgColor = const Color(0xFFEAF3E8);
        textColor = AppColors.primary;
        numBgColor = AppColors.primary;
        numTextColor = Colors.white;
      } else {
        borderColor = const Color(0xFFE8A09A);
        bgColor = const Color(0xFFFFF2F1);
        textColor = const Color(0xFFD04B44);
        numBgColor = const Color(0xFFE8A09A);
        numTextColor = Colors.white;
      }
    }

    return GestureDetector(
      onTap: () {
        if (correctConfirmed) {
          if (isCorrect) return;
          setState(() => _step3SelectedIndex = index);
          return;
        }
        setState(() {
          _step3SelectedIndex = index;
          if (_step3Evaluated && !_step3IsCorrect) _step3Evaluated = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: numBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: numTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                choice.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3WrongGuidance(String guidance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDAD8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💭 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              guidance,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD04B44),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3CorrectExplanation(String explanation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              explanation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3ActionButton(MindStep3 data) {
    final isConfirmed = _step3Evaluated && _step3IsCorrect;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showSuccessOverlay
            ? null
            : () {
                if (isConfirmed) {
                  _handleNext();
                } else {
                  if (_step3SelectedIndex == -1) return;
                  setState(() {
                    _step3Evaluated = true;
                    _step3IsCorrect =
                        _step3SelectedIndex == data.correctIndex;
                  });
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isConfirmed
                ? (data.nextButtonText.isNotEmpty
                    ? data.nextButtonText
                    : '다음 이야기 보기')
                : '이게 이유야! 🔍',
            key: ValueKey(isConfirmed),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 4 — 공감 반응 선택
  // ─────────────────────────────────────────────

  Widget _buildStep4({required Key key, required MindStep4 data}) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStep4LeoIntro(data.leoIntro),
          const SizedBox(height: 16),
          _buildQuestionPill(data.question),
          const SizedBox(height: 12),
          for (int i = 0; i < data.choices.length; i++) ...[
            _buildStep4Choice(data, i),
            if (i < data.choices.length - 1) const SizedBox(height: 10),
          ],
          if (_step4Evaluated &&
              _step4SelectedIndex != -1 &&
              _step4SelectedIndex != data.correctIndex) ...[
            const SizedBox(height: 12),
            _buildStep4WrongExplanation(
              data.choices[_step4SelectedIndex].feedback,
            ),
            const SizedBox(height: 8),
            _buildRetryHint(data.retryMessage),
          ],
          if (_step4Evaluated && _step4IsCorrect) ...[
            const SizedBox(height: 12),
            _buildSuccessBox(data.successMessage),
          ],
          const SizedBox(height: 16),
          _buildStep4ActionButton(data),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep4LeoIntro(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFF5C9B8),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/leo_defaultface.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Choice(MindStep4 data, int index) {
    final choice = data.choices[index];
    final isSelected = _step4SelectedIndex == index;
    final isCorrect = index == data.correctIndex;
    final correctConfirmed = _step4Evaluated && _step4IsCorrect;

    Color borderColor = const Color(0xFFEBE6DF);
    Color bgColor = Colors.white;
    Color textColor = AppColors.textMain;
    Color numBgColor = AppColors.cardLight;
    Color numTextColor = AppColors.textSub;

    if (correctConfirmed && isCorrect) {
      borderColor = AppColors.primary;
      bgColor = const Color(0xFFEAF3E8);
      textColor = AppColors.primary;
      numBgColor = AppColors.primary;
      numTextColor = Colors.white;
    } else if (isSelected) {
      if (!_step4Evaluated) {
        borderColor = AppColors.primary.withValues(alpha: 0.5);
        bgColor = const Color(0xFFF0F6EE);
        textColor = AppColors.primary;
        numBgColor = AppColors.primary.withValues(alpha: 0.5);
        numTextColor = Colors.white;
      } else if (isCorrect) {
        borderColor = AppColors.primary;
        bgColor = const Color(0xFFEAF3E8);
        textColor = AppColors.primary;
        numBgColor = AppColors.primary;
        numTextColor = Colors.white;
      } else {
        borderColor = const Color(0xFFE8A09A);
        bgColor = const Color(0xFFFFF2F1);
        textColor = const Color(0xFFD04B44);
        numBgColor = const Color(0xFFE8A09A);
        numTextColor = Colors.white;
      }
    }

    return GestureDetector(
      onTap: () {
        if (correctConfirmed) {
          if (isCorrect) return;
          setState(() => _step4SelectedIndex = index);
          return;
        }
        setState(() {
          _step4SelectedIndex = index;
          if (_step4Evaluated && !_step4IsCorrect) _step4Evaluated = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: numBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: numTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                choice.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4WrongExplanation(String explanation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDAD8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💭 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              explanation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD04B44),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4ActionButton(MindStep4 data) {
    final isConfirmed = _step4Evaluated && _step4IsCorrect;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_showSuccessOverlay || _isSaving)
            ? null
            : () {
                if (isConfirmed) {
                  _saveAndComplete();
                } else {
                  if (_step4SelectedIndex == -1) return;
                  setState(() {
                    _step4Evaluated = true;
                    _step4IsCorrect =
                        _step4SelectedIndex == data.correctIndex;
                  });
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isConfirmed
                ? (data.completeButtonText.isNotEmpty
                    ? data.completeButtonText
                    : '완료! 🎯')
                : '이렇게 말할게요! 💬',
            key: ValueKey(isConfirmed),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Placeholder (Step 미구현)
  // ─────────────────────────────────────────────

  Widget _buildComingSoonPlaceholder({
    required Key key,
    required String stepLabel,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🚧', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(
            '$stepLabel 준비 중!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '곧 만나볼 수 있어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentStep < _totalSteps - 1 ? '다음으로' : '완료!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
