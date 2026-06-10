import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'learning_screen.dart';
import 'conversation_screen.dart';
import 'friends_screen.dart';
import '../widgets/guide_tour_overlay.dart';
import '../widgets/rocket_animation.dart';
import '../theme/app_colors.dart';

class MainScaffold extends StatefulWidget {
  final bool isFirstVisit;

  const MainScaffold({super.key, this.isFirstVisit = false});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  String? _pendingChatTodoId;
  String? _pendingEmotionTodoId;

  bool _isGuideTourActive = false;
  bool _isRocketPlaying = false;
  GuideTourStep? _currentGuideTourStep;

  final GlobalKey _homeTabKey = GlobalKey();
  final GlobalKey _learningTabKey = GlobalKey();
  final GlobalKey _chatTabKey = GlobalKey();
  final GlobalKey _heartTabKey = GlobalKey();

  List<Widget> get _screens => [
    HomeScreen(onNavigateToTab: _navigateToTab),
    const LearningScreen(),
    ConversationScreen(
      pendingTodoId: _pendingChatTodoId,
      onTodoCompleted: () => setState(() => _pendingChatTodoId = null),
    ),
    FriendsScreen(
      pendingTodoId: _pendingEmotionTodoId,
      onTodoCompleted: () => setState(() => _pendingEmotionTodoId = null),
    ),
  ];

  void _navigateToTab(int index, {String? todoId}) {
    if (_isGuideTourActive || _isRocketPlaying) return;
    setState(() {
      _currentIndex = index;
      if (todoId != null) {
        if (index == 2) _pendingChatTodoId = todoId;
        if (index == 3) _pendingEmotionTodoId = todoId;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.isFirstVisit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGuideTour());
    }
  }

  void _startGuideTour() {
    setState(() {
      _isGuideTourActive = true;
      _currentGuideTourStep = GuideTourStep.welcomePopup;
    });
  }

  void _nextGuideTourStep() {
    setState(() {
      switch (_currentGuideTourStep!) {
        case GuideTourStep.welcomePopup:
          _currentGuideTourStep = GuideTourStep.homeTab;
          break;
        case GuideTourStep.homeTab:
          _currentGuideTourStep = GuideTourStep.learningTab;
          break;
        case GuideTourStep.learningTab:
          _currentGuideTourStep = GuideTourStep.chatTab;
          break;
        case GuideTourStep.chatTab:
          _currentGuideTourStep = GuideTourStep.heartTab;
          break;
        case GuideTourStep.heartTab:
          break;
      }
    });
  }

  void _finishGuideTour() {
    setState(() {
      _isGuideTourActive = false;
      _currentGuideTourStep = null;
      _isRocketPlaying = true;
    });
  }

  void _onRocketComplete() {
    setState(() => _isRocketPlaying = false);
  }

  GlobalKey? _getCurrentSpotlightKey() {
    switch (_currentGuideTourStep) {
      case GuideTourStep.homeTab:
        return _homeTabKey;
      case GuideTourStep.learningTab:
        return _learningTabKey;
      case GuideTourStep.chatTab:
        return _chatTabKey;
      case GuideTourStep.heartTab:
        return _heartTabKey;
      default:
        return null;
    }
  }

  int? _getHighlightedNavIndex() {
    if (!_isGuideTourActive) return null;
    switch (_currentGuideTourStep) {
      case GuideTourStep.homeTab:
        return 0;
      case GuideTourStep.learningTab:
        return 1;
      case GuideTourStep.chatTab:
        return 2;
      case GuideTourStep.heartTab:
        return 3;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: _screens[_currentIndex]),
          if (_isGuideTourActive && _currentGuideTourStep != null)
            GuideTourOverlay(
              currentStep: _currentGuideTourStep!,
              spotlightTargetKey: _getCurrentSpotlightKey(),
              onNext: _nextGuideTourStep,
              onFinish: _finishGuideTour,
            ),
          if (_isRocketPlaying) RocketAnimation(onComplete: _onRocketComplete),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final highlightedIndex = _getHighlightedNavIndex();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  containerKey: _homeTabKey,
                  index: 0,
                  currentIndex: _currentIndex,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: '홈',
                  isHighlighted: highlightedIndex == 0,
                  onTap: () {
                    if (_isGuideTourActive || _isRocketPlaying) return;
                    setState(() => _currentIndex = 0);
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  containerKey: _learningTabKey,
                  index: 1,
                  currentIndex: _currentIndex,
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: '공부방',
                  isHighlighted: highlightedIndex == 1,
                  onTap: () {
                    if (_isGuideTourActive || _isRocketPlaying) return;
                    setState(() => _currentIndex = 1);
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  containerKey: _chatTabKey,
                  index: 2,
                  currentIndex: _currentIndex,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: '레오랑 톡톡',
                  isHighlighted: highlightedIndex == 2,
                  onTap: () {
                    if (_isGuideTourActive || _isRocketPlaying) return;
                    setState(() => _currentIndex = 2);
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  containerKey: _heartTabKey,
                  index: 3,
                  currentIndex: _currentIndex,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: '친구랑',
                  isHighlighted: highlightedIndex == 3,
                  onTap: () {
                    if (_isGuideTourActive || _isRocketPlaying) return;
                    setState(() => _currentIndex = 3);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final GlobalKey? containerKey;
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _NavItem({
    this.containerKey,
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.isHighlighted) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isHighlighted && !old.isHighlighted) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isHighlighted && old.isHighlighted) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.currentIndex;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Container(
            key: widget.containerKey,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: widget.isHighlighted
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primary.withValues(
                      alpha: 0.07 + 0.1 * _anim.value,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: 0.25 + 0.45 * _anim.value,
                      ),
                      width: 2,
                    ),
                  )
                : null,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSelected
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F1DF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.activeIcon, color: AppColors.primary),
                  )
                : Icon(widget.icon, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
